//
//  CreateChallengeFeedPostSheet.swift
//  Lumey
//

import SwiftUI
import SwiftData
import PhotosUI

struct CreateChallengeFeedPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let currentUserID: String
    let currentUsername: String
    let onPostCreated: ((ChallengeFeedItemDTO) -> Void)?

    @Query(sort: \Book.title)
    private var books: [Book]

    @Query(sort: \ReadingChallenge.title)
    private var challenges: [ReadingChallenge]

    @State private var postText: String = ""
    @State private var photoCaption: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedBook: Book?
    @State private var selectedChallenge: ReadingChallenge?
    @State private var selectedMood: String = ""
    @State private var containsSpoilers = false
    @State private var visibility: ChallengePostVisibility = .publicPost

    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let moods = [
        "Cozy",
        "Excited",
        "Reflective",
        "Dramatic",
        "Soft",
        "Chaotic",
        "Inspired",
        "Curious",
        "Emotional",
        "Magical"
    ]

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedPhotoData != nil
    }

    var body: some View {
        ZStack {
            LumeyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        composerCard

                        photoCard

                        linkedDetailsCard

                        optionsCard

                        postButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 34)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadPhoto(from: newItem)
            }
        }
        .alert("Post Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Lumey could not create this feed post right now.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Post")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Share an update with the challenge feed")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LColors.bg)
                            .overlay(
                                Circle()
                                    .strokeBorder(LGradients.header, lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(LColors.bg.opacity(0.98))
        .safeAreaPadding(.top)
    }

    // MARK: - Composer

    private var composerCard: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    icon: "bookchat",
                    title: "Feed Update",
                    subtitle: "Write what you want to share."
                )

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $postText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 140)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.045))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )

                    if postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("What are you reading, thinking, loving, or ranting about?")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary.opacity(0.75))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    Text("\(postText.count)/3000")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(postText.count > 3000 ? LColors.gradientPurple : LColors.textSecondary)

                    Spacer()

                    if containsSpoilers {
                        miniBadge(text: "SPOILERS")
                    }

                    miniBadge(text: visibility.displayName.uppercased())
                }
            }
        }
    }

    // MARK: - Photo

    private var photoCard: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    icon: "image",
                    title: "Photo",
                    subtitle: "Optional, but cute."
                )

                if let photoData = selectedPhotoData,
                   let uiImage = UIImage(data: photoData) {
                    VStack(spacing: 12) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                            )

                        TextField("Photo caption optional", text: $photoCaption)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.045))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )

                        HStack(spacing: 10) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                smallActionButton(
                                    icon: "image",
                                    title: "Change Photo"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                selectedPhotoItem = nil
                                selectedPhotoData = nil
                                photoCaption = ""
                            } label: {
                                smallActionButton(
                                    icon: "trash",
                                    title: "Remove"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 12) {
                            Image("upload")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(LGradients.header)
                                .frame(width: 72, height: 72)
                                .background(
                                    Circle()
                                        .fill(LColors.glassSurface)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(LGradients.header, lineWidth: 1)
                                        )
                                )

                            VStack(spacing: 4) {
                                Text("Add a Photo")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Choose an optional image for your feed post.")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.045))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Linked Details

    private var linkedDetailsCard: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    icon: "link",
                    title: "Optional Links",
                    subtitle: "Attach a book or challenge."
                )

                Menu {
                    Button("No Book") {
                        selectedBook = nil
                    }

                    ForEach(books) { book in
                        Button(book.title) {
                            selectedBook = book
                        }
                    }
                } label: {
                    pickerRow(
                        icon: "openbook",
                        title: "Linked Book",
                        value: selectedBook?.title ?? "None"
                    )
                }

                Menu {
                    Button("No Challenge") {
                        selectedChallenge = nil
                    }

                    ForEach(challenges) { challenge in
                        Button(challenge.title) {
                            selectedChallenge = challenge
                        }
                    }
                } label: {
                    pickerRow(
                        icon: "startrophyfill",
                        title: "Linked Challenge",
                        value: selectedChallenge?.title ?? "None"
                    )
                }

                Menu {
                    Button("No Mood") {
                        selectedMood = ""
                    }

                    ForEach(moods, id: \.self) { mood in
                        Button(mood) {
                            selectedMood = mood
                        }
                    }
                } label: {
                    pickerRow(
                        icon: "sparkles",
                        title: "Mood",
                        value: selectedMood.isEmpty ? "None" : selectedMood
                    )
                }
            }
        }
    }

    // MARK: - Options

    private var optionsCard: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    icon: "settingswavy",
                    title: "Post Options",
                    subtitle: "Choose how this update should appear."
                )

                Toggle(isOn: $containsSpoilers) {
                    HStack(spacing: 10) {
                        Image("eyeoff")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(LGradients.header)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Contains Spoilers")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Marks this post so readers know before opening it.")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                    }
                }
                .toggleStyle(.switch)

                Picker("Visibility", selection: $visibility) {
                    ForEach(ChallengePostVisibility.allCases) { option in
                        Text(option.displayName)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Post Button

    private var postButton: some View {
        Button {
            Task {
                await submitPost()
            }
        } label: {
            HStack(spacing: 10) {
                if isPosting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image("send")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }

                Text(isPosting ? "Posting..." : "Post to Feed")
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(canPost && !isPosting ? AnyShapeStyle(LGradients.header) : AnyShapeStyle(LColors.glassSurface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(LGradients.header.opacity(canPost ? 1 : 0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canPost || isPosting)
    }

    // MARK: - Reusable Pieces

    private func sectionHeader(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 11) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(LGradients.header)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(LGradients.header, lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }

            Spacer()
        }
    }

    private func pickerRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(LGradients.header)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(LColors.glassSurface)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image("chevdown")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(LGradients.header)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func smallActionButton(
        icon: String,
        title: String
    ) -> some View {
        HStack(spacing: 7) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(LColors.glassSurface)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(LGradients.header, lineWidth: 1)
                )
        )
    }

    private func miniBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(LColors.glassSurface)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(LGradients.header, lineWidth: 1)
                    )
            )
    }

    // MARK: - Actions

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data
            }
        } catch {
            errorMessage = "Lumey could not load this photo."
            showError = true
        }
    }

    @MainActor
    private func submitPost() async {
        guard canPost else { return }

        let trimmedText = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = photoCaption.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.count > 3000 {
            errorMessage = "Your post is a little too long. Keep it under 3,000 characters."
            showError = true
            return
        }

        if trimmedCaption.count > 500 {
            errorMessage = "Your photo caption is a little too long. Keep it under 500 characters."
            showError = true
            return
        }

        isPosting = true

        do {
            let photoBase64: String?

            if let selectedPhotoData {
                photoBase64 = try await ChallengeSocialService.shared.uploadFeedPhoto(
                    imageData: selectedPhotoData
                )
            } else {
                photoBase64 = nil
            }

            let created = try await ChallengeSocialService.shared.createFeedPost(
                userID: currentUserID,
                username: currentUsername,
                text: trimmedText,
                photoURL: nil,
                photoBase64: photoBase64,
                photoCaption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                linkedBookID: selectedBook?.id.uuidString,
                linkedChallengeID: selectedChallenge?.id.uuidString,
                mood: selectedMood.isEmpty ? nil : selectedMood,
                containsSpoilers: containsSpoilers,
                visibility: visibility.rawValue
            )

            onPostCreated?(created)
            ReadingXPService.awardChallengeFeedPost(created, modelContext: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isPosting = false
    }
}

// MARK: - Visibility

private enum ChallengePostVisibility: String, CaseIterable, Identifiable {
    case publicPost = "public"
    case followers = "followers"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .publicPost:
            return "Public"
        case .followers:
            return "Followers"
        }
    }
}
