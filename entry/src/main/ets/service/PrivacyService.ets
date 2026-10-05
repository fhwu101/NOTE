import { userAuth } from '@kit.UserAuthenticationKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const PRIVACY_LOG_DOMAIN: number = 0x0000;
const PRIVACY_LOG_TAG: string = 'PrivacyService';

@ObservedV2
export class PrivacyState {
  @Trace incomeVisible: boolean = false;
  private static instance: PrivacyState | null = null;

  static getInstance(): PrivacyState {
    if (PrivacyState.instance === null) {
      PrivacyState.instance = new PrivacyState();
    }
    return PrivacyState.instance;
  }

  hideIncome(): void {
    this.incomeVisible = false;
  }

  requestShowIncome(onFailure: (message: string) => void): void {
    if (this.incomeVisible) {
      return;
    }
    const authParam: userAuth.AuthParam = {
      challenge: PrivacyState.buildChallenge(),
      authType: [userAuth.UserAuthType.PIN],
      authTrustLevel: userAuth.AuthTrustLevel.ATL2
    };
    const widgetParam: userAuth.WidgetParam = {
      title: '验证锁屏密码查看收入'
    };
    try {
      const authInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      authInstance.on('result', {
        onResult: (result: userAuth.UserAuthResult): void => {
          if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
            this.incomeVisible = true;
            return;
          }
          if (result.result === userAuth.UserAuthResultCode.CANCELED) {
            return;
          }
          onFailure(PrivacyState.messageOfCode(result.result));
        }
      });
      authInstance.start();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(PRIVACY_LOG_DOMAIN, PRIVACY_LOG_TAG,
        `start pin auth failed, code=${err.code}, message=${err.message}`);
      onFailure(PrivacyState.messageOfCode(err.code));
    }
  }

  private static buildChallenge(): Uint8Array {
    try {
      const rand = cryptoFramework.createRandom();
      const randData = rand.generateRandomSync(16).data;
      if (randData !== null && randData.length > 0) {
        return randData;
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(PRIVACY_LOG_DOMAIN, PRIVACY_LOG_TAG,
        `generate challenge failed, code=${err.code}, message=${err.message}`);
    }
    return new Uint8Array(16);
  }

  private static messageOfCode(code: number): string {
    if (code === userAuth.UserAuthResultCode.FAIL) {
      return '密码验证未通过';
    }
    if (code === userAuth.UserAuthResultCode.TIMEOUT) {
      return '验证超时，请重试';
    }
    if (code === userAuth.UserAuthResultCode.LOCKED) {
      return '验证次数过多已锁定，请稍后再试';
    }
    if (code === userAuth.UserAuthResultCode.NOT_ENROLLED) {
      return '未设置锁屏密码，请先在系统设置中配置';
    }
    if (code === userAuth.UserAuthResultCode.PIN_EXPIRED) {
      return '锁屏密码已过期，请更新后再试';
    }
    if (code === userAuth.UserAuthResultCode.BUSY) {
      return '系统繁忙，请稍后再试';
    }
    return '验证失败，请重试';
  }
}
