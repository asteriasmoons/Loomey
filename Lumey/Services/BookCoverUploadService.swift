import Foundation
import UIKit

// Uploads saved covers directly to Vox API, independently of the Mac.
// iOS can continue an already scheduled background file upload after suspension.
final class BookCoverUploadService: NSObject, URLSessionTaskDelegate, URLSessionDelegate {
    static let shared = BookCoverUploadService()
    private let queue = DispatchQueue(label: "im.lystaria.loomey.cover-uploads")
    private let directory: URL
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "im.lystaria.loomey.cover-uploads")
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CoverUploads", isDirectory: true)
        super.init()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        resumePending()
    }

    func preserve(title: String, author: String, isbn: String, image: Data) {
        guard !title.isEmpty, !author.isEmpty, !image.isEmpty, image.count <= 8 * 1024 * 1024 else { return }
        let mime: String
        if image.starts(with: [0xff, 0xd8, 0xff]) { mime = "image/jpeg" }
        else if image.starts(with: [0x89, 0x50, 0x4e, 0x47]) { mime = "image/png" }
        else if image.count > 12 && image.starts(with: Array("RIFF".utf8)) { mime = "image/webp" }
        else { return }
        let id = UUID().uuidString
        let boundary = "Loomey-\(id)"
        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".utf8))
        }
        field("title", title); field("author", author); field("isbns", isbn)
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"cover\"; filename=\"cover\"\r\nContent-Type: \(mime)\r\n\r\n".utf8))
        body.append(image)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        let file = directory.appendingPathComponent(id + ".upload")
        do { try body.write(to: file, options: .atomic) }
        catch { print("Could not queue cover upload: \(error)"); return }
        schedule(file, boundary: boundary)
    }

    private func schedule(_ file: URL, boundary: String) {
        guard let url = URL(string: "https://appapi.voxiverse.ink/api/books/covers/contribute") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let task = session.uploadTask(with: request, fromFile: file)
        task.taskDescription = file.lastPathComponent + "|" + boundary
        task.resume()
    }

    func resumePending() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.getAllTasks { tasks in
                let active = Set(tasks.compactMap { $0.taskDescription?.components(separatedBy: "|").first })
                let files = (try? FileManager.default.contentsOfDirectory(at: self.directory, includingPropertiesForKeys: nil)) ?? []
                for file in files where file.pathExtension == "upload" && !active.contains(file.lastPathComponent) {
                    // Each saved multipart payload contains its boundary in the first line.
                    guard let handle = try? FileHandle(forReadingFrom: file),
                          let prefix = try? handle.read(upToCount: 100),
                          let first = String(data: prefix, encoding: .utf8)?.components(separatedBy: "\r\n").first,
                          first.hasPrefix("--") else { continue }
                    try? handle.close()
                    self.schedule(file, boundary: String(first.dropFirst(2)))
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let description = task.taskDescription,
              let name = description.components(separatedBy: "|").first else { return }
        let status = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        if error == nil && (200...299).contains(status) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        } else {
            print("Cover upload pending retry (HTTP \(status)): \(error?.localizedDescription ?? "server error")")
        }
    }
}
