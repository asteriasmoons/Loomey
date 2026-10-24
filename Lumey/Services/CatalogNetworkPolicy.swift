import Foundation

final class CatalogNetworkPolicy: NSObject, URLSessionTaskDelegate {
    private let origin: URL?
    init(origin: URL? = nil) { self.origin = origin }

    static func safeURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme?.lowercased() == "https", url.host != nil,
              url.user == nil, url.password == nil,
              !(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []).contains(where: { $0.name.lowercased() == "apikey" }) else { return nil }
        return url
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard let url = request.url, Self.safeURL(url.absoluteString) != nil,
              origin == nil || (url.host == origin?.host && url.port == origin?.port && url.path.hasPrefix(origin?.path ?? "/")) else {
            CatalogDiagnostics.log("http.redirect_rejected", ["host": request.url?.host ?? "unknown", "status": response.statusCode])
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}
