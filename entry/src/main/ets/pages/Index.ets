import {
  Bill,
  DayGroup,
  DateUtils,
  BILL_TYPE_EXPENSE,
  BILL_TYPE_INCOME
} from '../model/Bill';
import { BillService } from '../service/BillService';
import { PrivacyState } from '../service/PrivacyService';

const MASKED_AMOUNT_TEXT: string = '¥ ****';

@Entry
@ComponentV2
struct Index {
  @Local currentMonth: string = DateUtils.currentMonth();
  @Local dayGroups: DayGroup[] = [];
  @Local monthIncome: number = 0;
  @Local monthExpense: number = 0;
  @Local privacy: PrivacyState = PrivacyState.getInstance();
  navPathStack: NavPathStack = new NavPathStack();
  private service: BillService = BillService.getInstance();

  aboutToAppear(): void {
    this.service.setDataChangedCallback(() => {
      this.refreshBills();
    });
    const ctx = this.getUIContext().getHostContext();
    if (ctx !== undefined) {
      this.service.init(ctx).then(() => {
        this.refreshBills();
      });
    }
  }

  private async refreshBills(): Promise<void> {
    const bills = await this.service.queryByMonth(this.currentMonth);
    const groupMap = new Map<string, DayGroup>();
    let income = 0;
    let expense = 0;
    bills.forEach((bill: Bill) => {
      if (bill.billType === BILL_TYPE_INCOME) {
        income += bill.amount;
      } else {
        expense += bill.amount;
      }
      let group: DayGroup | undefined = groupMap.get(bill.billDate);
      if (group === undefined) {
        group = new DayGroup();
        group.date = bill.billDate;
        groupMap.set(bill.billDate, group);
      }
      if (bill.billType === BILL_TYPE_INCOME) {
        group.income += bill.amount;
      } else {
        group.expense += bill.amount;
      }
      group.bills.push(bill);
    });
    const groups: DayGroup[] = [];
    groupMap.forEach((group: DayGroup) => {
      groups.push(group);
    });
    this.dayGroups = groups;
    this.monthIncome = income;
    this.monthExpense = expense;
  }

  private prevMonth(): void {
    this.currentMonth = DateUtils.prevMonth(this.currentMonth);
    this.refreshBills();
  }

  private nextMonth(): void {
    this.currentMonth = DateUtils.nextMonth(this.currentMonth);
    this.refreshBills();
  }

  private balanceValue(): number {
    return this.monthIncome - this.monthExpense;
  }

  private balanceText(): string {
    if (this.privacy.incomeVisible) {
      return `¥${this.balanceValue().toFixed(2)}`;
    }
    return MASKED_AMOUNT_TEXT;
  }

  private incomeText(): string {
    if (this.privacy.incomeVisible) {
      return `¥${this.monthIncome.toFixed(2)}`;
    }
    return MASKED_AMOUNT_TEXT;
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

  private goAdd(): void {
    this.navPathStack.pushPath({
      name: 'addBill',
      param: null,
      onPop: (popInfo: PopInfo) => {
        this.refreshBills();
      }
    });
  }

  private goQuery(): void {
    this.navPathStack.pushPath({
      name: 'billQuery',
      param: null,
      onPop: (popInfo: PopInfo) => {
        this.refreshBills();
      }
    });
  }

  private goReport(): void {
    this.navPathStack.pushPath({
      name: 'report',
      param: null,
      onPop: (popInfo: PopInfo) => {
        this.refreshBills();
      }
    });
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
    this.refreshBills();
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

  private daySummaryText(group: DayGroup): string {
    const parts: string[] = [];
    if (group.expense > 0) {
      parts.push(`支出 ¥${group.expense.toFixed(2)}`);
    }
    if (group.income > 0) {
      if (this.privacy.incomeVisible) {
        parts.push(`收入 ¥${group.income.toFixed(2)}`);
      } else {
        parts.push('收入 ****');
      }
    }
    return parts.join('  ');
  }

  @Builder
  SummaryCard() {
    Column() {
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.prevMonth();
          })
        Text(DateUtils.monthTitle(this.currentMonth))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text('>')
          .fontSize(20)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.nextMonth();
          })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12 })

      Row({ space: 16 }) {
        Column() {
          Text('本月支出')
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.8)')
          Text(`¥${this.monthExpense.toFixed(2)}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Text('本月收入')
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.8)')
          Row({ space: 6 }) {
            Text(this.incomeText())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            SymbolGlyph(this.privacy.incomeVisible ? $r('sys.symbol.eye') : $r('sys.symbol.eye_slash'))
              .fontSize(18)
              .fontColor(['rgba(255,255,255,0.75)'])
          }
          .alignItems(VerticalAlign.Center)
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.toggleIncome();
        })
      }
      .width('100%')
      .margin({ top: 20 })

      Row() {
        Text('本月结余')
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.8)')
        Blank()
        Text(this.balanceText())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .margin({ top: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FF6B3B')
    .borderRadius({ bottomLeft: 20, bottomRight: 20 })
  }

  @Builder
  GroupHeader(group: DayGroup) {
    Row() {
      Text(DateUtils.dayTitle(group.date))
        .fontSize(13)
        .fontColor('#999999')
      if (DateUtils.isToday(group.date)) {
        Text('今天')
          .fontSize(11)
          .fontColor('#FF6B3B')
          .backgroundColor('#FDEBDD')
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ left: 8 })
      }
      Blank()
      Text(this.daySummaryText(group))
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 6 })
  }

  @Builder
  BillRow(bill: Bill) {
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

      Text(this.billAmountText(bill))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.billAmountColor(bill))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
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
  ListHeader() {
    Row() {
      Text('收支明细')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Blank()
      Text('报表')
        .fontSize(14)
        .fontColor('#FF6B3B')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          this.goReport();
        })
      Text('查询记录')
        .fontSize(14)
        .fontColor('#FF6B3B')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .onClick(() => {
          this.goQuery();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 4 })
  }

  @Builder
  EmptyView() {
    Column() {
      Text('本月暂无记录')
        .fontSize(16)
        .fontColor('#999999')
      Text('点击右下角按钮，记下第一笔吧')
        .fontSize(13)
        .fontColor('#BBBBBB')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Navigation(this.navPathStack) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          this.SummaryCard()
          this.ListHeader()
          if (this.dayGroups.length === 0) {
            this.EmptyView()
          } else {
            List() {
              ForEach(this.dayGroups, (group: DayGroup) => {
                ListItemGroup({ header: (): void => {
                  this.GroupHeader(group)
                } }) {
                  ForEach(group.bills, (bill: Bill) => {
                    ListItem() {
                      this.BillRow(bill)
                    }
                    .swipeAction({
                      end: {
                        builder: (): void => {
                          this.DeleteAction(bill)
                        }
                      }
                    })
                  }, (bill: Bill) => `bill-${bill.id}`)
                }
                .divider({
                  strokeWidth: 1,
                  color: '#F0F0F0',
                  startMargin: 68,
                  endMargin: 16
                })
              }, (group: DayGroup) =>
                `group-${group.date}-${group.bills.length}-${group.expense}-${group.income}`)
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')

        Button('+')
          .width(56)
          .height(56)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor('#FF6B3B')
          .borderRadius(28)
          .margin(24)
          .shadow({ radius: 8, color: 'rgba(255,107,59,0.4)', offsetY: 4 })
          .onClick(() => {
            this.goAdd();
          })
      }
      .width('100%')
      .height('100%')
    }
    .title('我的账本')
    .mode(NavigationMode.Stack)
  }
}
