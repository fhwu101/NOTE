import {
  Bill,
  BillFilter,
  DateUtils,
  BILL_TYPE_EXPENSE,
  BILL_TYPE_INCOME
} from '../model/Bill';
import { BillService } from '../service/BillService';
import { PrivacyState } from '../service/PrivacyService';

const FILTER_TYPE_ALL: number = -1;

@ComponentV2
export struct BillQueryPage {
  @Local keyword: string = '';
  @Local filterType: number = FILTER_TYPE_ALL;
  @Local monthScopeOn: boolean = true;
  @Local filterMonth: string = DateUtils.currentMonth();
  @Local results: Bill[] = [];
  @Local sumIncome: number = 0;
  @Local sumExpense: number = 0;
  @Local privacy: PrivacyState = PrivacyState.getInstance();
  pathStack: NavPathStack = new NavPathStack();
  private service: BillService = BillService.getInstance();

  aboutToAppear(): void {
    this.doQuery();
  }

  private async doQuery(): Promise<void> {
    const filter = new BillFilter();
    filter.keyword = this.keyword.trim();
    filter.billType = this.filterType;
    if (this.monthScopeOn) {
      filter.month = this.filterMonth;
    }
    const bills = await this.service.queryBills(filter);
    let income = 0;
    let expense = 0;
    bills.forEach((bill: Bill) => {
      if (bill.billType === BILL_TYPE_INCOME) {
        income += bill.amount;
      } else {
        expense += bill.amount;
      }
    });
    this.results = bills;
    this.sumIncome = income;
    this.sumExpense = expense;
  }

  private setTypeFilter(t: number): void {
    this.filterType = t;
    this.doQuery();
  }

  private setMonthScope(on: boolean): void {
    this.monthScopeOn = on;
    this.doQuery();
  }

  private prevMonth(): void {
    this.filterMonth = DateUtils.prevMonth(this.filterMonth);
    this.doQuery();
  }

  private nextMonth(): void {
    this.filterMonth = DateUtils.nextMonth(this.filterMonth);
    this.doQuery();
  }

  private confirmDelete(bill: Bill): void {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: '确定删除这条记录吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.doDelete(bill);
        }
      }
    });
  }

  private async doDelete(bill: Bill): Promise<void> {
    await this.service.delete(bill.id);
    this.doQuery();
  }

  private typeChipColor(t: number): string {
    if (this.filterType === t) {
      return '#FFFFFF';
    }
    return '#666666';
  }

  private typeChipBg(t: number): string {
    if (this.filterType === t) {
      return '#FF6B3B';
    }
    return '#FFFFFF';
  }

  private scopeChipColor(on: boolean): string {
    if (this.monthScopeOn === on) {
      return '#FFFFFF';
    }
    return '#666666';
  }

  private scopeChipBg(on: boolean): string {
    if (this.monthScopeOn === on) {
      return '#FF6B3B';
    }
    return '#FFFFFF';
  }

  private billAmountText(bill: Bill): string {
    if (bill.billType === BILL_TYPE_INCOME) {
      if (!this.privacy.incomeVisible) {
        return '+¥ ****';
      }
      return `+¥${bill.amount.toFixed(2)}`;
    }
    return `-¥${bill.amount.toFixed(2)}`;
  }

  private billAmountColor(bill: Bill): string {
    if (bill.billType === BILL_TYPE_INCOME) {
      return '#F0833A';
    }
    return '#333333';
  }

  private billIconBgColor(bill: Bill): string {
    if (bill.billType === BILL_TYPE_INCOME) {
      return '#FDEBDD';
    }
    return '#EDF0F2';
  }

  private billIconFontColor(bill: Bill): string {
    if (bill.billType === BILL_TYPE_INCOME) {
      return '#F0833A';
    }
    return '#666666';
  }

  private resultSummaryText(): string {
    const incomeText = this.privacy.incomeVisible ? `¥${this.sumIncome.toFixed(2)}` : '****';
    return `共 ${this.results.length} 笔    支出 ¥${this.sumExpense.toFixed(2)}    收入 ${incomeText}`;
  }

  private incomeToggleText(): string {
    if (this.privacy.incomeVisible) {
      return '隐藏收入';
    }
    return '查看收入';
  }

  private toggleIncome(): void {
    if (this.privacy.incomeVisible) {
      this.privacy.hideIncome();
      return;
    }
    this.privacy.requestShowIncome((message: string) => {
      this.getUIContext().getPromptAction().showToast({ message: message });
    });
  }

  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      TextInput({ placeholder: '搜索备注或分类', text: this.keyword })
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .fontColor('#333333')
        .backgroundColor('#FFFFFF')
        .placeholderColor('#BBBBBB')
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.keyword = value;
        })
        .onSubmit((enterKey: EnterKeyType) => {
          this.doQuery();
        })
      Text('搜索')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#FF6B3B')
        .borderRadius(14)
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .onClick(() => {
          this.doQuery();
        })
    }
    .width('100%')
  }

  @Builder
  FilterBar() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('全部')
          .fontSize(13)
          .fontColor(this.typeChipColor(FILTER_TYPE_ALL))
          .backgroundColor(this.typeChipBg(FILTER_TYPE_ALL))
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            this.setTypeFilter(FILTER_TYPE_ALL);
          })
        Text('支出')
          .fontSize(13)
          .fontColor(this.typeChipColor(BILL_TYPE_EXPENSE))
          .backgroundColor(this.typeChipBg(BILL_TYPE_EXPENSE))
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            this.setTypeFilter(BILL_TYPE_EXPENSE);
          })
        Text('收入')
          .fontSize(13)
          .fontColor(this.typeChipColor(BILL_TYPE_INCOME))
          .backgroundColor(this.typeChipBg(BILL_TYPE_INCOME))
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            this.setTypeFilter(BILL_TYPE_INCOME);
          })
        Blank()
        if (this.monthScopeOn) {
          Text('<')
            .fontSize(16)
            .fontColor('#666666')
            .padding({ left: 8, right: 8 })
            .onClick(() => {
              this.prevMonth();
            })
          Text(DateUtils.monthTitle(this.filterMonth))
            .fontSize(13)
            .fontColor('#333333')
          Text('>')
            .fontSize(16)
            .fontColor('#666666')
            .padding({ left: 8, right: 8 })
            .onClick(() => {
              this.nextMonth();
            })
        }
      }
      .width('100%')

      Row({ space: 8 }) {
        Text('全部时间')
          .fontSize(13)
          .fontColor(this.scopeChipColor(false))
          .backgroundColor(this.scopeChipBg(false))
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            this.setMonthScope(false);
          })
        Text('按月查询')
          .fontSize(13)
          .fontColor(this.scopeChipColor(true))
          .backgroundColor(this.scopeChipBg(true))
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            this.setMonthScope(true);
          })
        Blank()
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ResultSummary() {
    Row() {
      Text(this.resultSummaryText())
        .fontSize(12)
        .fontColor('#999999')
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
      Text(this.incomeToggleText())
        .fontSize(12)
        .fontColor('#FF6B3B')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          this.toggleIncome();
        })
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 8, bottom: 4 })
  }

  @Builder
  QueryRow(bill: Bill) {
    Row() {
      Text(bill.category.substring(0, 1))
        .width(40)
        .height(40)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontColor(this.billIconFontColor(bill))
        .backgroundColor(this.billIconBgColor(bill))
        .borderRadius(20)

      Column() {
        Text(bill.category)
          .fontSize(16)
          .fontColor('#333333')
        if (bill.note.length > 0) {
          Text(bill.note)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12, right: 12 })

      Column() {
        Text(this.billAmountText(bill))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.billAmountColor(bill))
        Text(bill.billDate)
          .fontSize(11)
          .fontColor('#BBBBBB')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 6 })
  }

  @Builder
  DeleteAction(bill: Bill) {
    Button('删除')
      .height(44)
      .fontSize(15)
      .fontColor(Color.White)
      .backgroundColor('#E5484D')
      .borderRadius(12)
      .margin({ left: 12 })
      .onClick(() => {
        this.confirmDelete(bill);
      })
  }

  @Builder
  EmptyView() {
    Column() {
      Text('未找到符合条件的记录')
        .fontSize(15)
        .fontColor('#999999')
      Text('换个筛选条件试试')
        .fontSize(12)
        .fontColor('#BBBBBB')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        this.SearchBar()
        this.FilterBar()
        this.ResultSummary()
        if (this.results.length === 0) {
          this.EmptyView()
        } else {
          List() {
            ForEach(this.results, (bill: Bill) => {
              ListItem() {
                this.QueryRow(bill)
              }
              .swipeAction({
                end: {
                  builder: (): void => {
                    this.DeleteAction(bill)
                  }
                }
              })
            }, (bill: Bill) => `q-${bill.id}`)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6F7')
      .padding({ left: 12, right: 12, top: 12 })
    }
    .title('账单查询')
    .backgroundColor('#F5F6F7')
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .onBackPressed(() => {
      this.pathStack.pop(true);
      return true;
    })
  }
}

@Builder
export function BillQueryBuilder(): void {
  BillQueryPage()
}
