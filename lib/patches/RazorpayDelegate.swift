import Flutter
import Razorpay
import RazorpayCore
import UIKit

public class RazorpayDelegate: NSObject, RazorpayPaymentCompletionProtocolWithData, ExternalWalletSelectionProtocol, RazorpayEventCallback {

    static let CODE_PAYMENT_SUCCESS        = 0
    static let CODE_PAYMENT_ERROR          = 1
    static let CODE_PAYMENT_EXTERNAL_WALLET = 2
    static let NETWORK_ERROR        = 0
    static let INVALID_OPTIONS      = 1
    static let PAYMENT_CANCELLED    = 2
    static let TLS_ERROR            = 3
    static let INCOMPATIBLE_PLUGIN  = 3
    static let UNKNOWN_ERROR        = 100

    private var pendingResult: FlutterResult!
    private var subscribedAnalyticsEvents: [String]?
    var merchantEventSink: FlutterEventSink?
    private let logTag = "RazorpayFlutter"

    public func subscribeToAnalyticsEvents(events: [String]) {
        subscribedAnalyticsEvents = events
    }

    public func onEvent(_ payloadJson: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let sink = self.merchantEventSink else { return }
            sink(payloadJson)
        }
    }

    public func onExternalWalletSelected(_ walletName: String, withPaymentData paymentData: [AnyHashable: Any]?) {
        var response = [String: Any]()
        response["type"] = RazorpayDelegate.CODE_PAYMENT_EXTERNAL_WALLET
        var data = [String: Any]()
        data["external_wallet"] = walletName
        response["data"] = data
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingResult(response as NSDictionary)
        }
    }

    public func onPaymentSuccess(_ payment_id: String, andData data: [AnyHashable: Any]?) {
        print("[RazorpayFlutter] onPaymentSuccess called — payment_id: \(payment_id)")
        var successData = [String: Any]()
        successData["razorpay_payment_id"] = payment_id
        if let extraData = data {
            for (key, value) in extraData {
                if let k = key as? String { successData[k] = value }
            }
        }
        print("[RazorpayFlutter] successData keys: \(successData.keys.sorted())")
        var response = [String: Any]()
        response["type"] = RazorpayDelegate.CODE_PAYMENT_SUCCESS
        response["data"] = successData
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("[RazorpayFlutter] Calling pendingResult on main thread")
            self.pendingResult(response as NSDictionary)
        }
    }

    public func onPaymentError(_ code: Int32, description message: String, andData data: [AnyHashable: Any]?) {
        print("[RazorpayFlutter] onPaymentError — code: \(code) message: \(message)")
        var errorData = [String: Any]()
        errorData["code"]         = RazorpayDelegate.translateRzpPaymentError(errorCode: Int(code))
        errorData["message"]      = message
        errorData["responseBody"] = data ?? [:]
        var response = [String: Any]()
        response["type"] = RazorpayDelegate.CODE_PAYMENT_ERROR
        response["data"] = errorData
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingResult(response as NSDictionary)
        }
    }

    public func open(options: Dictionary<String, Any>, result: @escaping FlutterResult, from viewController: UIViewController?) {
        self.pendingResult = result
        let key = options["key"] as? String
        let razorpay = RazorpayCheckout.initWithKey(key ?? "", andDelegateWithData: self)
        razorpay.setExternalWalletSelectionDelegate(self)
        var mutableOptions = options
        mutableOptions["integration"] = "flutter"
        mutableOptions["FRAMEWORK"]   = "flutter"
        if let vc = viewController {
            razorpay.open(mutableOptions, displayController: vc)
        } else {
            razorpay.open(mutableOptions)
        }
    }

    public func resync(result: @escaping FlutterResult) { result(nil) }

    static func translateRzpPaymentError(errorCode: Int) -> Int {
        switch errorCode {
        case 0:  return NETWORK_ERROR
        case 1:  return INVALID_OPTIONS
        case 2:  return PAYMENT_CANCELLED
        default: return UNKNOWN_ERROR
        }
    }
}
