export const BILL_TYPE_EXPENSE: number = 0;
export const BILL_TYPE_INCOME: number = 1;

export class Bill {
  id: number = 0;
  billType: number = BILL_TYPE_EXPENSE;
  amount: number = 0;
  category: string = '';
  note: string = '';
  billDate: string = '';
  createTime: number = 0;
}

export class DayGroup {
  date: string = '';
  income: number = 0;
  expense: number = 0;
  bills: Bill[] = [];
}

export class BillFilter {
  keyword: string = '';
  billType: number = -1;
  month: string = '';
}

export class BillCategory {
  static readonly expenseList: string[] =
    ['餐饮', '交通', '购物', '居住', '娱乐', '医疗', '教育', '通讯', '其他'];
  static readonly incomeList: string[] =
    ['工资', '奖金', '理财', '兼职', '红包', '报销', '其他'];
}

export class DateUtils {
  static pad2(n: number): string {
    if (n < 10) {
      return `0${n}`;
    }
    return `${n}`;
  }

  static formatDate(d: Date): string {
    return `${d.getFullYear()}-${DateUtils.pad2(d.getMonth() + 1)}-${DateUtils.pad2(d.getDate())}`;
  }

  static parseDate(dateStr: string): Date {
    const year = Number(dateStr.substring(0, 4));
    const month = Number(dateStr.substring(5, 7)) - 1;
    const day = Number(dateStr.substring(8, 10));
    return new Date(year, month, day);
  }

  static today(): string {
    return DateUtils.formatDate(new Date());
  }

  static currentMonth(): string {
    return DateUtils.today().substring(0, 7);
  }

  static nextMonth(month: string): string {
    const year = Number(month.substring(0, 4));
    const mon = Number(month.substring(5, 7));
    if (mon === 12) {
      return `${year + 1}-01`;
    }
    return `${year}-${DateUtils.pad2(mon + 1)}`;
  }

  static prevMonth(month: string): string {
    const year = Number(month.substring(0, 4));
    const mon = Number(month.substring(5, 7));
    if (mon === 1) {
      return `${year - 1}-12`;
    }
    return `${year}-${DateUtils.pad2(mon - 1)}`;
  }

  static monthTitle(month: string): string {
    return `${month.substring(0, 4)}年${month.substring(5, 7)}月`;
  }

  static dayTitle(dateStr: string): string {
    const d = DateUtils.parseDate(dateStr);
    const weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const weekday = weekdays[d.getDay()];
    return `${d.getMonth() + 1}月${d.getDate()}日 ${weekday}`;
  }

  static isToday(dateStr: string): boolean {
    return dateStr === DateUtils.today();
  }
}
