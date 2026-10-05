import {
  Bill,
  DateUtils,
  BILL_TYPE_EXPENSE,
  BILL_TYPE_INCOME
} from '../model/Bill';
import { BillService } from '../service/BillService';
import { PrivacyState } from '../service/PrivacyService';

const MASKED_AMOUNT_TEXT: string = '¥ ****';
const EXPENSE_BAR_COLOR: string = '#FF6B3B';
const INCOME_BAR_COLOR: string = '#F0833A';
const INCOME_TREND_COLOR: string = '#69C0A0';
const TREND_CHART_HEIGHT: number = 120;
const PIE_COLORS: string[] =
  ['#FF6B3B', '#F7A468', '#FFC53D', '#7EB8FF', '#69C0A0', '#B5A9F5', '#F789A0', '#9FD65D', '#A2A2B0'];

class ReportCategoryStat {
  category: string = '';
  amount: number = 0;
  count: number = 0;
  percent: number = 0;
  colorIndex: number = 0;
}

class ReportDailyTrend {
  day: number = 0;
  expense: number = 0;
  income: number = 0;
}

class ReportDailyAmount {
  day: number = 0;
  amount: number = 0;
}

@ComponentV2
export struct ReportPage {
  @Local currentMonth: string = DateUtils.currentMonth();
  @Local totalIncome: number = 0;
  @Local totalExpense: number = 0;
  @Local expenseStats: ReportCategoryStat[] = [];
  @Local incomeStats: ReportCategoryStat[] = [];
  @Local dailyTrend: ReportDailyTrend[] = [];
  @Local trendMaxValue: number = 0;
  @Local monthBills: Bill[] = [];
  @Local categorySheetShow: boolean = false;
  @Local selectedCategory: string = '';
  @Local selectedIsIncome: boolean = false;
  @Local categoryBills: Bill[] = [];
  @Local categoryTrend: ReportDailyAmount[] = [];
  @Local categoryTrendMax: number = 0;
  @Local privacy: PrivacyState = PrivacyState.getInstance();
  pathStack: NavPathStack = new NavPathStack();
  private service: BillService = BillService.getInstance();

  aboutToAppear(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    const bills = await this.service.queryByMonth(this.currentMonth);
    let income = 0;
    let expense = 0;
    bills.forEach((bill: Bill) => {
      if (bill.billType === BILL_TYPE_INCOME) {
        income += bill.amount;
      } else {
        expense += bill.amount;
      }
    });
    this.totalIncome = income;
    this.totalExpense = expense;
    this.incomeStats = this.buildStats(bills, BILL_TYPE_INCOME);
    this.expenseStats = this.buildStats(bills, BILL_TYPE_EXPENSE);
    this.buildTrend(bills);
  }

  private buildTrend(bills: Bill[]): void {
    const dayCount = this.daysInMonth(this.currentMonth);
    const trend: ReportDailyTrend[] = [];
    for (let d = 1; d <= dayCount; d++) {
      const item = new ReportDailyTrend();
      item.day = d;
      trend.push(item);
    }
    bills.forEach((bill: Bill) => {
      const day = Number(bill.billDate.substring(8, 10));
      const item: ReportDailyTrend | undefined = trend[day - 1];
      if (item === undefined) {
        return;
      }
      if (bill.billType === BILL_TYPE_INCOME) {
        item.income += bill.amount;
      } else {
        item.expense += bill.amount;
      }
    });
    let maxValue = 0;
    trend.forEach((item: ReportDailyTrend) => {
      if (item.expense > maxValue) {
        maxValue = item.expense;
      }
      if (item.income > maxValue) {
        maxValue = item.income;
      }
    });
    this.dailyTrend = trend;
    this.trendMaxValue = maxValue;
    this.monthBills = bills;
  }

  private daysInMonth(month: string): number {
    const year = Number(month.substring(0, 4));
    const mon = Number(month.substring(5, 7));
    return new Date(year, mon, 0).getDate();
  }

  private buildStats(bills: Bill[], billType: number): ReportCategoryStat[] {
    const statMap = new Map<string, ReportCategoryStat>();
    let total = 0;
    bills.forEach((bill: Bill) => {
      if (bill.billType !== billType) {
        return;
      }
      total += bill.amount;
      let stat: ReportCategoryStat | undefined = statMap.get(bill.category);
      if (stat === undefined) {
        stat = new ReportCategoryStat();
        stat.category = bill.category;
        statMap.set(bill.category, stat);
      }
      stat.amount += bill.amount;
      stat.count += 1;
    });
    const stats: ReportCategoryStat[] = [];
    statMap.forEach((stat: ReportCategoryStat) => {
      if (total > 0) {
        stat.percent = stat.amount / total * 100;
      }
      stats.push(stat);
    });
    stats.sort((a: ReportCategoryStat, b: ReportCategoryStat): number => b.amount - a.amount);
    stats.forEach((stat: ReportCategoryStat, index: number) => {
      stat.colorIndex = index;
    });
    return stats;
  }

  private prevMonth(): void {
    this.currentMonth = DateUtils.prevMonth(this.currentMonth);
    this.refresh();
  }

  private nextMonth(): void {
    this.currentMonth = DateUtils.nextMonth(this.currentMonth);
    this.refresh();
  }

  private incomeText(): string {
    if (this.privacy.incomeVisible) {
      return `¥${this.totalIncome.toFixed(2)}`;
    }
    return MASKED_AMOUNT_TEXT;
  }

  private balanceText(): string {
    if (this.privacy.incomeVisible) {
      return `¥${(this.totalIncome - this.totalExpense).toFixed(2)}`;
    }
    return MASKED_AMOUNT_TEXT;
  }

  private statAmountText(stat: ReportCategoryStat, isIncome: boolean): string {
    if (isIncome && !this.privacy.incomeVisible) {
      return '¥ ****';
    }
    return `¥${stat.amount.toFixed(2)}`;
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

  private barColor(isIncome: boolean): string {
    if (isIncome) {
      return INCOME_BAR_COLOR;
    }
    return EXPENSE_BAR_COLOR;
  }

  private expenseBarHeight(item: ReportDailyTrend): number {
    if (this.trendMaxValue <= 0 || item.expense <= 0) {
      return 0;
    }
    return Math.max(2, Math.round(item.expense / this.trendMaxValue * (TREND_CHART_HEIGHT - 8)));
  }

  private incomeBarHeight(item: ReportDailyTrend): number {
    if (!this.privacy.incomeVisible) {
      return 0;
    }
    if (this.trendMaxValue <= 0 || item.income <= 0) {
      return 0;
    }
    return Math.max(2, Math.round(item.income / this.trendMaxValue * (TREND_CHART_HEIGHT - 8)));
  }

  private dayLabelText(item: ReportDailyTrend): string {
    return this.dayNumText(item.day);
  }

  private dayNumText(day: number): string {
    if (day === 1 || day % 5 === 0) {
      return `${day}`;
    }
    return '';
  }

  private openCategory(stat: ReportCategoryStat, isIncome: boolean): void {
    this.selectedCategory = stat.category;
    this.selectedIsIncome = isIncome;
    const targetType = isIncome ? BILL_TYPE_INCOME : BILL_TYPE_EXPENSE;
    const bills: Bill[] = this.monthBills.filter((bill: Bill): boolean =>
      bill.category === stat.category && bill.billType === targetType);
    bills.sort((a: Bill, b: Bill): number => b.createTime - a.createTime);
    this.categoryBills = bills;
    this.buildCategoryTrend(bills);
    this.categorySheetShow = true;
  }

  private buildCategoryTrend(bills: Bill[]): void {
    const dayCount = this.daysInMonth(this.currentMonth);
    const trend: ReportDailyAmount[] = [];
    for (let d = 1; d <= dayCount; d++) {
      const item = new ReportDailyAmount();
      item.day = d;
      trend.push(item);
    }
    bills.forEach((bill: Bill) => {
      const day = Number(bill.billDate.substring(8, 10));
      const item: ReportDailyAmount | undefined = trend[day - 1];
      if (item === undefined) {
        return;
      }
      item.amount += bill.amount;
    });
    let maxValue = 0;
    trend.forEach((item: ReportDailyAmount) => {
      if (item.amount > maxValue) {
        maxValue = item.amount;
      }
    });
    this.categoryTrend = trend;
    this.categoryTrendMax = maxValue;
  }

  private categoryTotalAmount(): number {
    let total = 0;
    this.categoryBills.forEach((bill: Bill) => {
      total += bill.amount;
    });
    return total;
  }

  private categoryAvgAmount(): number {
    if (this.categoryBills.length === 0) {
      return 0;
    }
    return this.categoryTotalAmount() / this.categoryBills.length;
  }

  private categoryMaxAmount(): number {
    let maxValue = 0;
    this.categoryBills.forEach((bill: Bill) => {
      if (bill.amount > maxValue) {
        maxValue = bill.amount;
      }
    });
    return maxValue;
  }

  private categoryAmountText(amount: number): string {
    if (this.selectedIsIncome && !this.privacy.incomeVisible) {
      return '¥ ****';
    }
    return `¥${amount.toFixed(2)}`;
  }

  private categoryBarHeight(item: ReportDailyAmount): number {
    if (this.selectedIsIncome && !this.privacy.incomeVisible) {
      return 0;
    }
    if (this.categoryTrendMax <= 0 || item.amount <= 0) {
      return 0;
    }
    return Math.max(2, Math.round(item.amount / this.categoryTrendMax * 72));
  }

  private topExpenseStats(): ReportCategoryStat[] {
    return this.expenseStats.slice(0, 9);
  }

  private pieValues(): number[] {
    return this.topExpenseStats().map((stat: ReportCategoryStat): number => stat.amount);
  }

  private pieColors(): Array<ResourceColor> {
    return this.topExpenseStats().map((stat: ReportCategoryStat): string => this.pieColor(stat.colorIndex));
  }

  private pieColor(index: number): string {
    if (index >= 0 && index < PIE_COLORS.length) {
      return PIE_COLORS[index];
    }
    return PIE_COLORS[PIE_COLORS.length - 1];
  }

  private iconBgColor(isIncome: boolean): string {
    if (isIncome) {
      return '#FDEBDD';
    }
    return '#EDF0F2';
  }

  private iconFontColor(isIncome: boolean): string {
    if (isIncome) {
      return '#F0833A';
    }
    return '#666666';
  }

  @Builder
  MonthBar() {
    Row() {
      Text('<')
        .fontSize(20)
        .fontColor('#333333')
        .padding({ left: 12, right: 12 })
        .onClick(() => {
          this.prevMonth();
        })
      Text(DateUtils.monthTitle(this.currentMonth))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text('>')
        .fontSize(20)
        .fontColor('#333333')
        .padding({ left: 12, right: 12 })
        .onClick(() => {
          this.nextMonth();
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  SummaryCard() {
    Column() {
      Row({ space: 16 }) {
        Column() {
          Text('本月支出')
            .fontSize(13)
            .fontColor('#666666')
          Text(`¥${this.totalExpense.toFixed(2)}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B3B')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text('本月收入')
            .fontSize(13)
            .fontColor('#666666')
          Row({ space: 6 }) {
            Text(this.incomeText())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F0833A')
            SymbolGlyph(this.privacy.incomeVisible ? $r('sys.symbol.eye') : $r('sys.symbol.eye_slash'))
              .fontSize(16)
              .fontColor(['#BBBBBB'])
          }
          .alignItems(VerticalAlign.Center)
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .onClick(() => {
          this.toggleIncome();
        })
      }
      .width('100%')

      Row() {
        Text('本月结余')
          .fontSize(13)
          .fontColor('#666666')
        Blank()
        Text(this.balanceText())
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .margin({ top: 14 })
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(16)
  }

  @Builder
  TrendLegendDot(dotColor: string, leftMargin: number) {
    Column()
      .width(8)
      .height(8)
      .borderRadius(2)
      .backgroundColor(dotColor)
      .margin({ left: leftMargin })
  }

  @Builder
  TrendCard() {
    Column() {
      Row() {
        Text('本月收支趋势')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Row({ space: 4 }) {
          this.TrendLegendDot(EXPENSE_BAR_COLOR, 0)
          Text('支出')
            .fontSize(11)
            .fontColor('#999999')
          this.TrendLegendDot(INCOME_TREND_COLOR, 6)
          Text('收入')
            .fontSize(11)
            .fontColor('#999999')
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')

      Row() {
        ForEach(this.dailyTrend, (item: ReportDailyTrend) => {
          this.TrendDayCell(item)
        }, (item: ReportDailyTrend) =>
          `t-${item.day}-${item.expense.toFixed(2)}-${this.privacy.incomeVisible ? item.income.toFixed(2) : 'm'}`)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(16)
    .margin({ top: 12 })
  }

  @Builder
  TrendDayCell(item: ReportDailyTrend) {
    Column() {
      Row({ space: 1 }) {
        Column()
          .width(3)
          .height(this.expenseBarHeight(item))
          .backgroundColor(EXPENSE_BAR_COLOR)
          .borderRadius(1)
        Column()
          .width(3)
          .height(this.incomeBarHeight(item))
          .backgroundColor(INCOME_TREND_COLOR)
          .borderRadius(1)
      }
      .alignItems(VerticalAlign.Bottom)
      .height(TREND_CHART_HEIGHT)

      Text(this.dayLabelText(item))
        .fontSize(9)
        .fontColor('#BBBBBB')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LegendRow(stat: ReportCategoryStat) {
    Row({ space: 6 }) {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.pieColor(stat.colorIndex))
      Text(stat.category)
        .fontSize(12)
        .fontColor('#333333')
      Blank()
      Text(`${stat.percent.toFixed(1)}%`)
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
  }

  @Builder
  ExpensePieCard() {
    Column() {
      Row() {
        Text('支出占比')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text(`合计 ¥${this.totalExpense.toFixed(2)}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')

      Row({ space: 16 }) {
        Stack() {
          DataPanel({
            values: this.pieValues(),
            max: 0,
            type: DataPanelType.Circle
          })
            .width(132)
            .height(132)
            .valueColors(this.pieColors())
            .trackBackgroundColor('#F0F0F0')
            .strokeWidth(16)
            .closeEffect(true)
          Column() {
            Text('支出')
              .fontSize(11)
              .fontColor('#999999')
            Text(`¥${this.totalExpense.toFixed(2)}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B3B')
              .margin({ top: 2 })
          }
        }
        .width(132)
        .height(132)

        Column({ space: 8 }) {
          ForEach(this.topExpenseStats(), (stat: ReportCategoryStat) => {
            this.LegendRow(stat)
          }, (stat: ReportCategoryStat) => `l-${stat.category}-${stat.percent.toFixed(1)}`)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(16)
    .margin({ top: 12 })
  }

  @Builder
  SectionCard(title: string, totalText: string, stats: ReportCategoryStat[], isIncome: boolean) {
    Column() {
      Row() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text(totalText)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')

      ForEach(stats, (stat: ReportCategoryStat) => {
        this.StatRow(stat, isIncome)
      }, (stat: ReportCategoryStat) => `${isIncome ? 'i' : 'e'}-${stat.category}-${stat.amount.toFixed(2)}-${stat.count}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(16)
    .margin({ top: 12 })
  }

  @Builder
  StatRow(stat: ReportCategoryStat, isIncome: boolean) {
    Column() {
      Row() {
        Text(stat.category.substring(0, 1))
          .width(34)
          .height(34)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .fontColor(this.iconFontColor(isIncome))
          .backgroundColor(this.iconBgColor(isIncome))
          .borderRadius(17)

        Column() {
          Text(stat.category)
            .fontSize(15)
            .fontColor('#333333')
          Text(`${stat.count} 笔`)
            .fontSize(11)
            .fontColor('#BBBBBB')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10, right: 10 })

        Column() {
          Text(this.statAmountText(stat, isIncome))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.barColor(isIncome))
          Text(`${stat.percent.toFixed(1)}%`)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Row() {
        Row()
          .width(`${stat.percent.toFixed(1)}%`)
          .height(6)
          .backgroundColor(this.barColor(isIncome))
          .borderRadius(3)
      }
      .width('100%')
      .backgroundColor('#F0F0F0')
      .borderRadius(3)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => {
      this.openCategory(stat, isIncome);
    })
  }

  @Builder
  CategorySheetBuilder() {
    Column() {
      Text(`${this.selectedCategory} · ${DateUtils.monthTitle(this.currentMonth)}`)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 12, bottom: 12 })

      Row({ space: 8 }) {
        this.CategoryStatItem('总金额', this.categoryAmountText(this.categoryTotalAmount()))
        this.CategoryStatItem('笔数', `${this.categoryBills.length}笔`)
        this.CategoryStatItem('平均单笔', this.categoryAmountText(this.categoryAvgAmount()))
        this.CategoryStatItem('最大单笔', this.categoryAmountText(this.categoryMaxAmount()))
      }
      .width('100%')
      .backgroundColor('#F5F6F7')
      .borderRadius(10)
      .padding({ top: 10, bottom: 10 })

      Text('每日分布')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 14 })

      if (this.selectedIsIncome && !this.privacy.incomeVisible) {
        Text('收入已隐藏，验证锁屏密码后可查看分布')
          .fontSize(12)
          .fontColor('#BBBBBB')
          .margin({ top: 10 })
      } else {
        Row() {
          ForEach(this.categoryTrend, (item: ReportDailyAmount) => {
            this.CategoryTrendDayCell(item)
          }, (item: ReportDailyAmount) => `c-${item.day}-${item.amount.toFixed(2)}`)
        }
        .width('100%')
        .margin({ top: 8 })
      }

      Row() {
        Text('账单明细')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Text(`${this.categoryBills.length} 笔`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 14, bottom: 4 })

      List() {
        ForEach(this.categoryBills, (bill: Bill) => {
          ListItem() {
            this.CategoryBillRow(bill)
          }
        }, (bill: Bill) => `cb-${bill.id}`)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 0, endMargin: 0 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  CategoryStatItem(labelText: string, valueText: string) {
    Column() {
      Text(labelText)
        .fontSize(11)
        .fontColor('#999999')
      Text(valueText)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CategoryTrendDayCell(item: ReportDailyAmount) {
    Column() {
      Row() {
        Column()
          .width(5)
          .height(this.categoryBarHeight(item))
          .backgroundColor(this.barColor(this.selectedIsIncome))
          .borderRadius(2)
      }
      .alignItems(VerticalAlign.Bottom)
      .height(76)

      Text(this.dayNumText(item.day))
        .fontSize(9)
        .fontColor('#BBBBBB')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CategoryBillRow(bill: Bill) {
    Row() {
      Column() {
        Text(bill.billDate.substring(5))
          .fontSize(13)
          .fontColor('#333333')
        if (bill.note.length > 0) {
          Text(bill.note)
            .fontSize(11)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ right: 12 })

      Text(this.categoryAmountText(bill.amount))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.barColor(this.selectedIsIncome))
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  EmptyView() {
    Column() {
      Text('本月暂无记录')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        this.MonthBar()
        this.SummaryCard()
        Scroll() {
          Column() {
            if (this.expenseStats.length === 0 && this.incomeStats.length === 0) {
              this.EmptyView()
            } else {
              this.TrendCard()
              if (this.expenseStats.length > 0) {
                this.ExpensePieCard()
                this.SectionCard('支出构成', `合计 ¥${this.totalExpense.toFixed(2)}`, this.expenseStats, false)
              }
              if (this.incomeStats.length > 0) {
                this.SectionCard('收入构成', `合计 ¥${this.totalIncome.toFixed(2)}`, this.incomeStats, true)
              }
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 24 })
          .bindSheet(this.categorySheetShow, this.CategorySheetBuilder(), {
            showClose: true,
            height: SheetSize.LARGE,
            onDisappear: () => {
              this.categorySheetShow = false;
            }
          })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6F7')
      .padding({ top: 4 })
    }
    .title('收支报表')
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
export function ReportBuilder(): void {
  ReportPage()
}
