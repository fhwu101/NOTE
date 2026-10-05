import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Bill, BillFilter, DateUtils, BILL_TYPE_EXPENSE, BILL_TYPE_INCOME } from '../model/Bill';

const DOMAIN: number = 0x0000;
const TAG: string = 'BillService';

const CREATE_TABLE_SQL: string = `CREATE TABLE IF NOT EXISTS bill (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type INTEGER NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  note TEXT,
  date TEXT NOT NULL,
  createTime INTEGER NOT NULL
)`;

export class BillService {
  private static instance: BillService | undefined = undefined;

  private store: relationalStore.RdbStore | undefined = undefined;
  private appContext: common.Context | undefined = undefined;
  private initPromise: Promise<void> | undefined = undefined;
  private dataChangedCallback: (() => void) | undefined = undefined;

  static getInstance(): BillService {
    if (BillService.instance === undefined) {
      BillService.instance = new BillService();
    }
    return BillService.instance;
  }

  setDataChangedCallback(callback: () => void): void {
    this.dataChangedCallback = callback;
  }

  private notifyDataChanged(): void {
    if (this.dataChangedCallback !== undefined) {
      this.dataChangedCallback();
    }
  }

  async init(context: common.Context): Promise<void> {
    this.appContext = context;
    if (this.initPromise === undefined) {
      this.initPromise = this.doInit();
    }
    await this.initPromise;
  }

  private async doInit(): Promise<void> {
    const ctx = this.appContext;
    if (ctx === undefined) {
      return;
    }
    const config: relationalStore.StoreConfig = {
      name: 'bills.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      const rdbStore = await relationalStore.getRdbStore(ctx, config);
      await rdbStore.executeSql(CREATE_TABLE_SQL);
      this.store = rdbStore;
    } catch (error) {
      this.initPromise = undefined;
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'init db failed: %{public}s %{public}s',
        `${err.code}`, `${err.message}`);
    }
  }

  async insert(bill: Bill): Promise<boolean> {
    if (this.store === undefined) {
      hilog.error(DOMAIN, TAG, 'insert failed: store not ready');
      return false;
    }
    const bucket: relationalStore.ValuesBucket = {
      'type': bill.billType,
      'amount': bill.amount,
      'category': bill.category,
      'note': bill.note,
      'date': bill.billDate,
      'createTime': bill.createTime
    };
    try {
      const rowId = await this.store.insert('bill', bucket);
      if (rowId >= 0) {
        this.notifyDataChanged();
        return true;
      }
      return false;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'insert failed: %{public}s %{public}s',
        `${err.code}`, `${err.message}`);
      return false;
    }
  }

  async delete(id: number): Promise<void> {
    if (this.store === undefined) {
      return;
    }
    const predicates = new relationalStore.RdbPredicates('bill');
    predicates.equalTo('id', id);
    try {
      await this.store.delete(predicates);
      this.notifyDataChanged();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'delete failed: %{public}s %{public}s',
        `${err.code}`, `${err.message}`);
    }
  }

  private async queryByPredicates(predicates: relationalStore.RdbPredicates): Promise<Bill[]> {
    const result: Bill[] = [];
    if (this.store === undefined) {
      return result;
    }
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.query(predicates,
        ['id', 'type', 'amount', 'category', 'note', 'date', 'createTime']);
      while (resultSet.goToNextRow()) {
        const bill = new Bill();
        bill.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        bill.billType = resultSet.getLong(resultSet.getColumnIndex('type'));
        bill.amount = resultSet.getDouble(resultSet.getColumnIndex('amount'));
        bill.category = resultSet.getString(resultSet.getColumnIndex('category'));
        const noteIdx = resultSet.getColumnIndex('note');
        if (!resultSet.isColumnNull(noteIdx)) {
          bill.note = resultSet.getString(noteIdx);
        }
        bill.billDate = resultSet.getString(resultSet.getColumnIndex('date'));
        bill.createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
        result.push(bill);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'query failed: %{public}s %{public}s',
        `${err.code}`, `${err.message}`);
    } finally {
      if (resultSet !== undefined) {
        resultSet.close();
      }
    }
    return result;
  }

  async queryByMonth(month: string): Promise<Bill[]> {
    const predicates = new relationalStore.RdbPredicates('bill');
    predicates.greaterThanOrEqualTo('date', `${month}-01`)
      .lessThan('date', `${DateUtils.nextMonth(month)}-01`)
      .orderByDesc('date')
      .orderByDesc('createTime');
    return this.queryByPredicates(predicates);
  }

  async queryBills(filter: BillFilter): Promise<Bill[]> {
    const predicates = new relationalStore.RdbPredicates('bill');
    if (filter.billType === BILL_TYPE_EXPENSE || filter.billType === BILL_TYPE_INCOME) {
      predicates.equalTo('type', filter.billType);
    }
    if (filter.month.length > 0) {
      predicates.greaterThanOrEqualTo('date', `${filter.month}-01`)
        .lessThan('date', `${DateUtils.nextMonth(filter.month)}-01`);
    }
    if (filter.keyword.length > 0) {
      const kw: string = `%${filter.keyword}%`;
      predicates.beginWrap()
        .like('note', kw)
        .or()
        .like('category', kw)
        .endWrap();
    }
    predicates.orderByDesc('date')
      .orderByDesc('createTime');
    return this.queryByPredicates(predicates);
  }
}
