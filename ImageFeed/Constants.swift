import Foundation
import UIKit

enum WebViewConstants {
    static let unsplashBaseURLString = "https://unsplash.com"
    static let unsplashAuthorizeURLString = unsplashBaseURLString + "/oauth/authorize"
    static let unsplashTokenURLString = unsplashBaseURLString + "/oauth/token"
}

enum Constants {
    static let accessKey = "O-6fDORkh6TWWC7u_I4KfVhdTvt3eNozGJQT2-jZMkg"
    static let secretKey = "xQynh2PMY7Y26WD43S84GKjHIKd8_5ATaA1zS0nSHeo"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
}

enum OtherConstants {
    static let floatComparisonEpsilon: Double = 0.0001
}
