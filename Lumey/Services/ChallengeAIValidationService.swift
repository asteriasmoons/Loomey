//
//  ChallengeAIValidationService.swift
//  Lumey
//

import Foundation

// MARK: - AI Validation Packet

struct ChallengeAIValidationPacket: Codable {
    let challengeTitle: String
    let requirementText: String
    let requiredThemes: [String]
    let bookTitles: [String]
    let bookSummaries: [String]
    let bookGenres: [[String]]
    let bookMoods: [[String]]
    let bookTags: [[String]]
    let bookTropes: [[String]]
    let submissionNote: String
    let linkedReviewText: String?
}

// MARK: - AI Validation Response

struct ChallengeAIValidationResponse: Codable {
    let status: String        // "approved", "needsMoreInfo", "rejected"
    let message: String
}

// MARK: - Photo Validation

struct ChallengePhotoValidationPacket: Codable {
    let challengeTitle: String
    let requirementText: String
    let validationType: String
    let requiredThemes: [String]
    let bookTitles: [String]
    let submissionNote: String
    let proofSummary: String
    let photoURL: String
}

struct ChallengePhotoValidationResponse: Codable {
    let status: String
    let message: String
    let confidence: Double
    let visibleEvidence: [String]
    let missingEvidence: [String]
}

// MARK: - Challenge AI Validation Service

final class ChallengeAIValidationService {

    private let baseURL: String

    init(baseURL: String = "https://appapi.voxiverse.ink") {
        self.baseURL = baseURL
    }

    /// Sends a compact validation packet to the backend AI endpoint.
    /// Returns a ChallengeValidationResult.
    func validate(packet: ChallengeAIValidationPacket) async throws -> ChallengeValidationResult {
        guard let url = URL(string: "\(baseURL)/api/lumey/challenges/validate-theme") else {
            throw ChallengeAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(packet)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChallengeAIError.serverError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let decoded = try JSONDecoder().decode(ChallengeAIValidationResponse.self, from: data)

        switch decoded.status.lowercased() {
        case "approved":
            return .approved(decoded.message)
        case "needsmoreinfo":
            return .needsMoreInfo(decoded.message)
        case "rejected":
            return .rejected(decoded.message)
        default:
            return .needsMoreInfo(decoded.message)
        }
    }

    /// Sends a hosted proof photo and challenge context to the backend Puter validator.
    func validatePhoto(packet: ChallengePhotoValidationPacket) async throws -> ChallengePhotoValidationResponse {
        guard let url = URL(string: "\(baseURL)/api/lumey/challenges/validate-photo") else {
            throw ChallengeAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(packet)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChallengeAIError.serverError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        return try JSONDecoder().decode(ChallengePhotoValidationResponse.self, from: data)
    }

    /// Builds a compact validation packet from challenge and book data.
    static func buildPacket(
        challenge: ReadingChallenge,
        books: [Book],
        submissionNote: String,
        reviewText: String? = nil
    ) -> ChallengeAIValidationPacket {
        ChallengeAIValidationPacket(
            challengeTitle: challenge.title,
            requirementText: challenge.requirementText,
            requiredThemes: challenge.requiredThemes,
            bookTitles: books.map(\.title),
            bookSummaries: books.map { $0.summary.prefix(300).description },
            bookGenres: books.map(\.genres),
            bookMoods: books.map(\.moods),
            bookTags: books.map(\.tags),
            bookTropes: books.map(\.tropes),
            submissionNote: submissionNote,
            linkedReviewText: reviewText
        )
    }

    static func buildPhotoPacket(
        challenge: ReadingChallenge,
        books: [Book],
        submission: ChallengeSubmission
    ) -> ChallengePhotoValidationPacket {
        ChallengePhotoValidationPacket(
            challengeTitle: challenge.title,
            requirementText: challenge.requirementText,
            validationType: challenge.validationType.rawValue,
            requiredThemes: challenge.requiredThemes,
            bookTitles: books.map(\.title),
            submissionNote: submission.submissionNote,
            proofSummary: submission.proofSummary,
            photoURL: submission.photoURL
        )
    }
}

// MARK: - Errors

enum ChallengeAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid validation URL."
        case .invalidResponse:
            return "Received an invalid response from the validation server."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}
