import {
  Bill,
  BillCategory,
  DateUtils,
  BILL_TYPE_EXPENSE,
  BILL_TYPE_INCOME
} from '../model/Bill';
import { BillService } from '../service/BillService';

@ComponentV2
export struct AddBillPage {
  @Local billType: number = BILL_TYPE_EXPENSE;
  @Local category: string = BillCategory.expenseList[0];
  @Local amountText: string = '';
  @Local noteText: string = '';
  @Local billDate: string = DateUtils.today();
  pathStack: NavPathStack = new NavPathStack();
  private service: BillService = BillService.getInstance();

  private currentCategories(): string[] {
    if (this.billType === BILL_TYPE_EXPENSE) {
      return BillCategory.expenseList;
    }
    return BillCategory.incomeList;
  }

  private switchType(newType: number): void {
    if (this.billType === newType) {
      return;
    }
    this.billType = newType;
    this.category = this.currentCategories()[0];
  }

  private typeTextColor(t: number): string {
    if (t === this.billType) {
      return '#FFFFFF';
    }
    return '#666666';
  }

  private typeBgColor(t: number): string {
    if (t === this.billType) {
      return '#FF6B3B';
    }
    return '#F1F3F5';
  }

  private typeFontWeight(t: number): FontWeight {
    if (t === this.billType) {
      return FontWeight.Bold;
    }
    return FontWeight.Normal;
  }

  private amountInputColor(): string {
    if (this.billType === BILL_TYPE_INCOME) {
      return '#F0833A';
    }
    return '#333333';
  }

  private chipFontColor(cat: string): string {
    if (this.category === cat) {
      return '#FFFFFF';
    }
    return '#333333';
  }

  private chipBgColor(cat: string): string {
    if (this.category === cat) {
      return '#FF6B3B';
    }
    return '#F1F3F5';
  }

  private pickDate(): void {
    this.getUIContext().showDatePickerDialog({
      selected: DateUtils.parseDate(this.billDate),
      onDateAccept: (value: Date) => {
        this.billDate = DateUtils.formatDate(value);
      }
    });
  }

  private async saveBill(): Promise<void> {
    const amount = Number(this.amountText);
    if (!(amount > 0)) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的金额' });
      return;
    }
    const bill = new Bill();
    bill.billType = this.billType;
    bill.amount = amount;
    bill.category = this.category;
    bill.note = this.noteText;
    bill.billDate = this.billDate;
    bill.createTime = Date.now();
    const ok = await this.service.insert(bill);
    if (ok) {
      this.pathStack.pop(true, true);
    } else {
      this.getUIContext().getPromptAction().showToast({ message: '保存失败，请重试' });
    }
  }

  @Builder
  TypeToggle() {
    Row() {
      Text('支出')
        .layoutWeight(1)
        .height(44)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontWeight(this.typeFontWeight(BILL_TYPE_EXPENSE))
        .fontColor(this.typeTextColor(BILL_TYPE_EXPENSE))
        .backgroundColor(this.typeBgColor(BILL_TYPE_EXPENSE))
        .borderRadius({ topLeft: 22, bottomLeft: 22 })
        .onClick(() => {
          this.switchType(BILL_TYPE_EXPENSE);
        })
      Text('收入')
        .layoutWeight(1)
        .height(44)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontWeight(this.typeFontWeight(BILL_TYPE_INCOME))
        .fontColor(this.typeTextColor(BILL_TYPE_INCOME))
        .backgroundColor(this.typeBgColor(BILL_TYPE_INCOME))
        .borderRadius({ topRight: 22, bottomRight: 22 })
        .onClick(() => {
          this.switchType(BILL_TYPE_INCOME);
        })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
  }

  @Builder
  AmountCard() {
    Column() {
      Text('金额')
        .fontSize(14)
        .fontColor('#999999')
      TextInput({ placeholder: '0.00', text: this.amountText })
        .type(InputType.NUMBER_DECIMAL)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.amountInputColor())
        .placeholderColor('#CCCCCC')
        .placeholderFont({ size: 32, weight: FontWeight.Bold })
        .backgroundColor('#FFFFFF')
        .padding({ left: 0, right: 0 })
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.amountText = value;
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder
  CategoryCard() {
    Column() {
      Text('分类')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 4 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.currentCategories(), (cat: string) => {
          Text(cat)
            .fontSize(15)
            .fontColor(this.chipFontColor(cat))
            .backgroundColor(this.chipBgColor(cat))
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .margin({ right: 10, bottom: 10 })
            .onClick(() => {
              this.category = cat;
            })
        }, (cat: string) => `${this.billType}-${cat}`)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder
  DateCard() {
    Row() {
      Text('日期')
        .fontSize(15)
        .fontColor('#333333')
      Blank()
      Text(this.billDate)
        .fontSize(15)
        .fontColor('#FF6B3B')
        .onClick(() => {
          this.pickDate();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder
  NoteCard() {
    Row() {
      Text('备注')
        .fontSize(15)
        .fontColor('#333333')
        .margin({ right: 12 })
      TextInput({ placeholder: '点击填写（选填）', text: this.noteText })
        .layoutWeight(1)
        .fontSize(15)
        .backgroundColor('#FFFFFF')
        .placeholderColor('#BBBBBB')
        .onChange((value: string) => {
          this.noteText = value;
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 12 })
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            this.TypeToggle()
            this.AmountCard()
            this.CategoryCard()
            this.DateCard()
            this.NoteCard()
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)

        Button('保存')
          .width('90%')
          .height(48)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor('#FF6B3B')
          .borderRadius(24)
          .margin({ bottom: 24 })
          .onClick(() => {
            this.saveBill();
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6F7')
    }
    .title('记一笔')
    .backgroundColor('#F5F6F7')
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
  }
}

@Builder
export function AddBillBuilder(): void {
  AddBillPage()
}
