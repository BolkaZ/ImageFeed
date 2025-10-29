import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() { }
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NSError(domain: "Не получилось создать запрос", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let token = json["access_token"] as? String {
                        print("Токен получен: \(token)")
                        OAuth2TokenStorage.shared.token = token
                        completion(.success(token))
                    } else {
                        print("В ответе нет токена")
                        completion(.failure(NSError(domain: "Нет токена", code: 0, userInfo: nil)))
                    }
                } catch {
                    print("Ошибка чтения JSON: \(error)")
                    completion(.failure(error))
                }
                
            case .failure(let error):
                print("Ошибка сети или HTTP-статус: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        guard let authTokenUrl = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        return request
    }
}
