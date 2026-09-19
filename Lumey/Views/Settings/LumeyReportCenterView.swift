import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct LumeyReportCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingBugReport = false
    @State private var showingBetaFeedback = false
    @State private var showingFeatureRequest = false
    @State private var showingSubmitted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                LumeyReportHeader(eyebrow: "VOXIVERSE", title: "Send a Report") {
                    dismiss()
                }

                Button { showingBugReport = true } label: {
                    reportCard(
                        title: "Bug Report",
                        subtitle: "Tell Voxiverse what went wrong.",
                        asset: "bug"
                    )
                }
                .buttonStyle(.plain)

                Button { showingBetaFeedback = true } label: {
                    reportCard(
                        title: "Beta Feedback",
                        subtitle: "Share what you tested and how it felt.",
                        asset: "chatsparkle"
                    )
                }
                .buttonStyle(.plain)

                Button { showingFeatureRequest = true } label: {
                    reportCard(
                        title: "Feature Request",
                        subtitle: "Request something new for Loomey.",
                        asset: "brightbulb"
                    )
                }
                .buttonStyle(.plain)

                Button { showingSubmitted = true } label: {
                    reportCard(
                        title: "Submitted",
                        subtitle: "View reports sent from this device.",
                        asset: "inbox"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, LSpacing.pageHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background { LumeyBackground() }
        .lumeyReportAdaptivePresentation(isPresented: $showingBugReport, useFullScreenCover: horizontalSizeClass == .regular) {
            LumeyBugReportView()
        }
        .lumeyReportAdaptivePresentation(isPresented: $showingBetaFeedback, useFullScreenCover: horizontalSizeClass == .regular) {
            LumeyBetaFeedbackView()
        }
        .lumeyReportAdaptivePresentation(isPresented: $showingFeatureRequest, useFullScreenCover: horizontalSizeClass == .regular) {
            LumeyFeatureRequestView()
        }
        .lumeyReportAdaptivePresentation(isPresented: $showingSubmitted, useFullScreenCover: horizontalSizeClass == .regular) {
            LumeySubmittedReportsView()
        }
    }

    private func reportCard(title: String, subtitle: String, asset: String) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 14) {
                LumeyReportIcon(asset: asset, size: 54, iconSize: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(LGradients.header)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LumeySubmittedReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \SubmittedReport.submittedAt, order: .reverse) private var reports: [SubmittedReport]
    @State private var selectedReport: SubmittedReport?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                LumeyReportHeader(eyebrow: "REPORTS", title: "Submitted") {
                    dismiss()
                }

                if reports.isEmpty {
                    GlassCard(cornerRadius: 22) {
                        VStack(spacing: 10) {
                            Image("inbox")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(LGradients.header)
                            Text("No submitted reports")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(reports) { report in
                            Button { selectedReport = report } label: {
                                submittedReportCard(report)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, LSpacing.pageHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background { LumeyBackground() }
        .lumeyReportAdaptivePresentation(isPresented: selectedReportPresented, useFullScreenCover: horizontalSizeClass == .regular) {
            if let selectedReport {
                LumeySubmittedReportDetailView(report: selectedReport)
            }
        }
    }

    private func submittedReportCard(_ report: SubmittedReport) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                LumeyReportIcon(asset: reportIconName(for: report), size: 48, iconSize: 22)

                VStack(alignment: .leading, spacing: 5) {
                    Text(report.title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(report.submittedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                    Text(report.reportType)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                    Text(report.reportID)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LGradients.header)
                }

                Spacer(minLength: 8)

                if !report.attachments.isEmpty {
                    Image("imagesign")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(LGradients.header)
                }

                Image("chevright")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(LGradients.header)
            }
        }
    }

    private func reportIconName(for report: SubmittedReport) -> String {
        switch report.reportType {
        case "Beta Feedback":
            return "chatsparkle"
        case "Feature Request":
            return "brightbulb"
        default:
            return "document"
        }
    }

    private var selectedReportPresented: Binding<Bool> {
        Binding(
            get: { selectedReport != nil },
            set: { if !$0 { selectedReport = nil } }
        )
    }
}

struct LumeySubmittedReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let report: SubmittedReport
    @State private var selectedAttachment: SubmittedReportAttachment?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let attachmentColumns = [
        GridItem(.adaptive(minimum: 112, maximum: 112), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                LumeyReportHeader(eyebrow: report.reportType, title: report.title) {
                    dismiss()
                }
                reportDetails
                attachmentsSection
            }
            .padding(.horizontal, LSpacing.pageHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background { LumeyBackground() }
        .lumeyReportAdaptivePresentation(isPresented: selectedAttachmentPresented, useFullScreenCover: horizontalSizeClass == .regular) {
            if let selectedAttachment {
                LumeySubmittedReportImageView(attachment: selectedAttachment)
            }
        }
    }

    @ViewBuilder
    private var reportDetails: some View {
        if report.reportType == "Feature Request" {
            featureRequestDetails
        } else if report.reportType == "Beta Feedback" {
            betaFeedbackDetails
        } else {
            bugReportDetails
        }
    }

    private var featureRequestDetails: some View {
        VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "Submitted", value: report.submittedAt.formatted(date: .abbreviated, time: .omitted))
                metadataTile(label: "Report ID", value: report.reportID)
                metadataTile(label: "Area", value: report.category)
                metadataTile(label: "Feature Type", value: report.featureType)
                metadataTile(label: "Importance", value: report.featureImportance)
                metadataTile(label: "Who Is This For?", value: report.intendedAudience)
                metadataTile(label: "Where Should It Live?", value: report.desiredLocation)
                metadataTile(label: "Saved Data", value: report.requiresSavedData)
                metadataTile(label: "Notifications", value: report.needsNotifications)
                metadataTile(label: "Sharing", value: report.needsSharing)
                metadataTile(label: "AI", value: report.needsAI)
            }

            reportTextSection(title: "What Should the Feature Do?", text: report.featureDescription)
            reportTextSection(title: "How Should It Work?", text: report.imaginedWorkflow)
            if !report.relatedExistingFeature.trimmed.isEmpty {
                reportTextSection(title: "Related Existing Feature", text: report.relatedExistingFeature)
            }
            reportTextSection(title: "Problem or Limitation", text: report.problemAddressed)
            reportTextSection(title: "Desired Result", text: report.desiredResult)
            if !report.additionalDetails.trimmed.isEmpty {
                reportTextSection(title: "Additional Details", text: report.additionalDetails)
            }
            diagnosticsSection
        }
    }

    private var betaFeedbackDetails: some View {
        VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "Submitted", value: report.submittedAt.formatted(date: .abbreviated, time: .omitted))
                metadataTile(label: "Report Type", value: report.reportType)
                metadataTile(label: "Area", value: report.category)
                metadataTile(label: "Experience", value: report.overallExperience)
                metadataTile(label: "Report ID", value: report.reportID)
            }

            reportTextSection(title: "What Did You Test?", text: report.testedWhat)
            reportTextSection(title: "What Worked Well?", text: report.workedWell)
            reportTextSection(title: "What Could Be Better?", text: report.couldBeBetter)
            reportTextSection(title: "Anything Unexpected?", text: report.unexpected)
            reportTextSection(title: "Additional Thoughts", text: report.additionalNotes)
            diagnosticsSection
        }
    }

    private var bugReportDetails: some View {
        VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "Submitted", value: report.submittedAt.formatted(date: .abbreviated, time: .omitted))
                metadataTile(label: "Status", value: report.status)
                metadataTile(label: "Area", value: report.category)
                metadataTile(label: "Severity", value: report.severity)
                metadataTile(label: "Frequency", value: report.frequency)
                metadataTile(label: "Report ID", value: report.reportID)
            }

            reportTextSection(title: "What Happened", text: report.descriptionText)
            reportTextSection(title: "Expected Behavior", text: report.expectedBehavior)

            if !report.steps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    LumeyReportSectionHeader(title: "Steps to Reproduce")
                    GlassCard(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(report.steps.indices, id: \.self) { index in
                                HStack(alignment: .center, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(LColors.bg)
                                        .frame(width: 28, height: 28)
                                        .background(LGradients.tag, in: Circle())
                                    Text(report.steps[index])
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(LColors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                }
            }

            reportTextSection(title: "Additional Notes", text: report.additionalNotes)
            diagnosticsSection
        }
    }

    @ViewBuilder
    private var attachmentsSection: some View {
        if !report.attachments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                LumeyReportSectionHeader(title: report.reportType == "Feature Request" ? "Reference Images" : "Attachments")
                LazyVGrid(columns: attachmentColumns, spacing: 12) {
                    ForEach(report.attachments.sorted { $0.createdAt < $1.createdAt }) { attachment in
                        Button { selectedAttachment = attachment } label: {
                            LumeySubmittedReportAttachmentCard(attachment: attachment)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LumeyReportSectionHeader(title: "Diagnostics")
            LazyVGrid(columns: columns, spacing: 12) {
                metadataTile(label: "App", value: report.appName)
                metadataTile(label: "Version", value: report.appVersion)
                metadataTile(label: "Build", value: report.buildNumber)
                metadataTile(label: "Device", value: report.deviceModel)
                metadataTile(label: "iOS", value: report.iOSVersion)
                metadataTile(label: "Screen", value: displayScreenName)
            }
        }
    }

    private var displayScreenName: String {
        let trimmed = report.screenName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let last = trimmed.split(separator: ">", omittingEmptySubsequences: true).last {
            return String(last).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    private func metadataTile(label: String, value: String) -> some View {
        GlassCard(cornerRadius: 18, padding: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(LColors.textSecondary)
                Text(value.trimmed.isEmpty ? "Not provided" : value)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(value.trimmed.isEmpty ? AnyShapeStyle(LColors.textSecondary) : AnyShapeStyle(LColors.textPrimary))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func reportTextSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LumeyReportSectionHeader(title: title)
            GlassCard(cornerRadius: 22) {
                Text(text.trimmed.isEmpty ? "Not provided" : text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(text.trimmed.isEmpty ? LColors.textSecondary : LColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var selectedAttachmentPresented: Binding<Bool> {
        Binding(
            get: { selectedAttachment != nil },
            set: { if !$0 { selectedAttachment = nil } }
        )
    }
}

struct LumeySubmittedReportImageView: View {
    @Environment(\.dismiss) private var dismiss
    let attachment: SubmittedReportAttachment

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image = UIImage(data: attachment.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                Text("Image unavailable")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
            }

            Button { dismiss() } label: {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 44, height: 44)
                    .background(LColors.glassSurface, in: Circle())
                    .overlay { Circle().strokeBorder(LColors.glassBorder, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .padding()
        }
    }
}

enum LumeyReportFormOptions {
    static let areas = [
        "General",
        "Main Tab Bar",
        "More Tabs Menu",
        "Home",
        "Currently Reading",
        "Library Pulse",
        "Writing Stats",
        "Reading Momentum",
        "Home Recommendations",
        "Recommendation Collections",
        "Recommendation Collection Detail",
        "Recommended Book Detail",
        "Book Library",
        "Book List",
        "Book Row",
        "Book Status Filter",
        "Book Series Filter",
        "Book Custom Filters",
        "Add / Edit Book",
        "Book Identity",
        "Book Basic Info",
        "Book Reading Details",
        "Book Progress",
        "Book Ebook Page Conversion",
        "Book Organization",
        "Book Flags",
        "Book Cover",
        "Book Rating",
        "Book Format",
        "Book Ownership",
        "Book Genres",
        "Book Moods",
        "Book Topics",
        "Book Tags",
        "Book Tropes",
        "Book Search",
        "Book Search Results",
        "Book Recommendations",
        "Book Details",
        "Book Details Enrichment",
        "Book Metadata Enrichment",
        "ISBN Lookup",
        "Cover Image Picker",
        "Book Notes",
        "Add / Edit Book Note",
        "Book Quotes",
        "Add / Edit Book Quote",
        "Book Reviews",
        "Add / Edit Book Review",
        "Book Insights",
        "Reading Insight Review",
        "Reading Genres",
        "Reading Lists",
        "Add / Edit Reading List",
        "Reading List Detail",
        "Reading List Book Summary",
        "Reading Mission",
        "Reading Mission Generator",
        "Reading Mission History",
        "Reading Mission Completion",
        "Reading Mission Scoring",
        "Reading Mission Stats",
        "EPUB Library",
        "EPUB Collections",
        "EPUB File Access",
        "EPUB Quick Look",
        "EPUB Reader",
        "EPUB Reader Destination",
        "EPUB Reader Chrome",
        "EPUB Contents",
        "EPUB Bookmarks",
        "Add EPUB Bookmark",
        "EPUB Highlights",
        "EPUB Highlight Menu",
        "EPUB Notes & Quotes",
        "Reader Settings",
        "Reading Goals",
        "Add / Edit Goal",
        "Goal Icon Picker",
        "Goal Detail",
        "Goal Check-In",
        "Goal Notes",
        "Add Goal Note",
        "Goal Note Detail",
        "Goal Notes Timeline",
        "Goal Completion History",
        "Goal Milestones",
        "Goal Type Shelf",
        "Active Goals",
        "Completed Goals",
        "Paused Goals",
        "Reading Timer",
        "Mini Reading Timer",
        "Timer Live Activity",
        "Log Session",
        "Edit Reading Session",
        "Reading Sessions",
        "Reading Activity Detection",
        "Session History",
        "Reading Stats",
        "Stats Calendar",
        "Stats Favorites",
        "Stats Milestones",
        "Reading History",
        "Reading Insights",
        "Reading Insight Capture",
        "Reading Dreams",
        "Add / Edit Reading Dream",
        "Completed Dreams",
        "Reading Achievements",
        "Achievement Manager",
        "Reading XP / Levels",
        "XP Scoring",
        "XP Events",
        "Reading Personality",
        "Reading Break",
        "Reading Break Settings",
        "Reading Streaks",
        "Daily Reading Streak",
        "Weekend Reading Streak",
        "Weekly Reading Streak",
        "Monthly Reading Streak",
        "Reading Bingos",
        "Bingo Boards",
        "Bingo Board Detail",
        "Bingo Progress",
        "Bingo Catalog",
        "Bingo Engine",
        "Bingo Squares",
        "Bingo Lines",
        "Bingo Blackouts",
        "Challenges",
        "Featured Challenge",
        "Weekly Challenges",
        "Active Challenges",
        "Challenge Categories",
        "Reading Habit Challenges",
        "Pages Challenges",
        "Book Completion Challenges",
        "Genre Challenges",
        "Review Challenges",
        "Rating Challenges",
        "Series Challenges",
        "Author Challenges",
        "Seasonal Challenges",
        "Book Length Challenges",
        "Collection Challenges",
        "Fun Challenges",
        "Challenge Detail",
        "Challenge Submission",
        "Challenge Submission Result",
        "Challenge Proof Summary",
        "Challenge Validation",
        "Challenge Validation Types",
        "Challenge AI Validation",
        "Challenge Recurrence",
        "Challenge Status",
        "Challenge Feed",
        "Create Challenge Feed Post",
        "Challenge Feed Post",
        "Challenge Feed Entry",
        "Challenge Announcements",
        "Challenge Comments",
        "Challenge Messages",
        "Messages List",
        "Challenge Conversation",
        "Challenge Leaderboard",
        "Challenge Profile",
        "Challenge User Profile",
        "Challenge Bookmarks",
        "Completed Challenges",
        "Challenge Likes",
        "Buddies",
        "Buddy Reading",
        "Buddy Groups",
        "Buddy Group Picker",
        "Buddy Group Chat",
        "Buddy Announcements",
        "Post Buddy Announcement",
        "Buddy Announcement Board",
        "Buddy Announcement Archive",
        "Buddy Group Leave",
        "Buddy Group Close",
        "Buddy Join Requests",
        "Buddy Progress Updates",
        "Buddy Display Name",
        "Buddy Socket / Sync",
        "Sprints",
        "Sprint Room",
        "Sprint Active Banner",
        "Sprint Countdown",
        "Start / Join Sprint",
        "Start Sprint",
        "Join Sprint",
        "End Sprint",
        "Submit Sprint Pages",
        "Sprint Chat",
        "Sprint Chat Clear",
        "Sprint Participants",
        "Sprint Leaderboard",
        "Sprint Points",
        "Sprint Display Name",
        "Sprint Socket / Sync",
        "Profile",
        "Profile Username",
        "Profile Avatar",
        "Profile About",
        "Profile Followers",
        "Profile Following",
        "Profile Messages",
        "Profile Current Challenge",
        "Profile Recent Challenge Entries",
        "Reading DNA",
        "Year in Books",
        "Settings",
        "Theme Settings",
        "App Theme Settings",
        "Theme Picker",
        "Theme Preview",
        "Custom Icons",
        "Icon Picker",
        "Release Notes",
        "Report Center",
        "Submitted Reports",
        "Data Vault",
        "Goodreads Import",
        "Goodreads CSV Parsing",
        "Goodreads Import Review",
        "Goodreads Duplicate Review",
        "Goodreads Undo",
        "Import Cleanup",
        "Loomey Export",
        "Loomey CSV Export",
        "Loomey Library Export Document",
        "Library Import / Export",
        "CloudKit / Sync",
        "CloudKit Library",
        "App State",
        "User Settings",
        "Library Settings",
        "Sign In / Account",
        "Authentication",
        "User Profile Service",
        "Keychain",
        "Book Recommendation Service",
        "Recommendation Summary Service",
        "Recommendation Detail Service",
        "Recommendation Collection Service",
        "Voxiverse Submission Service",
        "Widgets",
        "Notifications",
        "Notification Manager",
        "Live Activities",
        "Bug Report",
        "Beta Feedback",
        "Feature Request",
        "Submitted Report Detail",
        "Report Attachments",
        "Report Diagnostics"
    ]

    static let featureTypes = [
        "New Feature", "Enhancement to Existing Feature", "New Tool",
        "New View or Screen", "New Integration", "Automation",
        "Customization Option", "Accessibility", "Import / Export",
        "Widget", "Other"
    ]
}

struct LumeyReportFormScaffold<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                content
            }
            .padding(.horizontal, LSpacing.pageHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .lumeyDismissKeyboardOnTap()
        .background { LumeyBackground() }
    }
}

struct LumeyReportHeader: View {
    let eyebrow: String
    let title: String
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(LColors.textSecondary)

                Text(title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.headingPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: close) {
                Image("xmarkwavy")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(LGradients.header)
                    .frame(width: 44, height: 44)
                    .background(LColors.glassSurface, in: Circle())
                    .overlay { Circle().strokeBorder(LColors.glassBorder, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }
}

struct LumeyReportIcon: View {
    let asset: String
    let size: CGFloat
    let iconSize: CGFloat

    var body: some View {
        Image(asset)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(LGradients.header)
            .frame(width: size, height: size)
            .background(LColors.glassSurface, in: Circle())
            .overlay { Circle().strokeBorder(LColors.glassBorder, lineWidth: 1) }
    }
}

struct LumeyReportInfoCard: View {
    let title: String
    let message: String

    var body: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LumeyReportSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(LColors.headingPrimary)
    }
}

struct LumeyReportTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textPrimary)
                .tint(LColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
        }
    }
}

struct LumeyReportTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary.opacity(0.72))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 18)
                }

                TextEditor(text: $text)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)
                    .tint(LColors.accent)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .frame(minHeight: minHeight)
                    .padding(10)
            }
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
        }
    }
}

struct LumeyReportPickerField: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                        isExpanded.toggle()
                    }
                } label: {
                    pickerLabel
                }
                .buttonStyle(.plain)

                if isExpanded {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(options, id: \.self) { option in
                                Button {
                                    selection = option
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
                                        isExpanded = false
                                    }
                                } label: {
                                    HStack {
                                        Text(option)
                                            .font(.system(size: 14, weight: option == selection ? .black : .semibold, design: .rounded))
                                            .foregroundStyle(option == selection ? LColors.textPrimary : LColors.textSecondary)
                                        Spacer()
                                        if option == selection {
                                            Image("checkwavy")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 13, height: 13)
                                                .foregroundStyle(LGradients.header)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                                    .frame(minHeight: dropdownRowHeight)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .frame(height: dropdownHeight)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var pickerLabel: some View {
        HStack {
            Text(selection)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(LColors.textPrimary)
            Spacer()
            Image("chevdown")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(LColors.textSecondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LColors.iconContainer.primary))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.border.nestedStrong, lineWidth: 1))
    }

    private var dropdownRowHeight: CGFloat { 42 }

    private var dropdownHeight: CGFloat {
        CGFloat(min(options.count, 4)) * dropdownRowHeight
    }
}

struct LumeyReportDynamicStepsField: View {
    let title: String
    @Binding var steps: [String]
    let maxSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(title)
            VStack(spacing: 10) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(alignment: .center, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.bg)
                            .frame(width: stepControlSize, height: stepControlSize)
                            .background(LGradients.tag, in: Circle())
                            .overlay {
                                Circle()
                                    .strokeBorder(LColors.glassBorder.opacity(0.75), lineWidth: 1)
                            }
                            .shadow(color: LColors.gradientPurple.opacity(0.22), radius: 8, y: 4)

                        LumeyReportTextField(
                            title: "",
                            placeholder: "Step \(index + 1)",
                            text: $steps[index]
                        )

                        if steps.count > 1 {
                            Button {
                                steps.remove(at: index)
                            } label: {
                                Image("xmarkwavy")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)
                                    .foregroundStyle(LColors.textSecondary)
                                    .frame(width: stepControlSize, height: stepControlSize)
                                    .background(LColors.glassSurface, in: Circle())
                                    .overlay {
                                        Circle()
                                            .strokeBorder(LColors.glassBorder.opacity(0.75), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if steps.count < maxSteps {
                    Button {
                        steps.append("")
                    } label: {
                        HStack(spacing: 8) {
                            Image("addwavy")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text("Add Step")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(LGradients.header)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(LColors.glassSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(LColors.glassBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stepControlSize: CGFloat { 36 }
}

struct LumeyReportAttachmentsPicker: View {
    let title: String
    @Binding var selectedPhotos: [PhotosPickerItem]
    let attachmentData: [Data]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LumeyReportSectionHeader(title: title)
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 3, matching: .images) {
                GlassCard(cornerRadius: 18) {
                    HStack(spacing: 14) {
                        Image("image")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(LGradients.header)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Add Screenshots")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                            Text("Up to 3 images")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }

                        Spacer()

                        Text("\(attachmentData.count)/3")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct LumeyReportDiagnosticsCard: View {
    let screenName: String

    var body: some View {
        LumeyReportInfoCard(
            title: "Automatic Diagnostics",
            message: "Loomey will include its app version, build number, device model, iOS version, screen, and submission time from \(screenName)."
        )
    }
}

struct LumeyReportStatusCards: View {
    let successTitle: String
    let reportID: String?
    let error: String?

    var body: some View {
        VStack(spacing: 10) {
            if let error {
                GlassCard(cornerRadius: 18) {
                    Text(error)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LColors.danger)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let reportID {
                GlassCard(cornerRadius: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(successTitle)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.success)
                        Text("Voxiverse report ID: \(reportID)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct LumeyReportSubmitButton: View {
    let title: String
    let sendingTitle: String
    let canSubmit: Bool
    let isSubmitting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(LColors.bg)
                } else {
                    Image("sendbutton")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                }

                Text(isSubmitting ? sendingTitle : title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .foregroundStyle(LColors.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(LGradients.header, in: RoundedRectangle(cornerRadius: LSpacing.buttonRadius))
            .opacity(canSubmit ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }
}

struct LumeySubmittedReportAttachmentCard: View {
    let attachment: SubmittedReportAttachment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))

                if let image = UIImage(data: attachment.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipped()
                } else {
                    Image("imagesign")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(LColors.textSecondary)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LColors.glassBorder, lineWidth: 1)
            }

            Text(attachment.displayName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
                .lineLimit(1)
                .frame(width: 96, alignment: .center)
        }
        .padding(8)
        .frame(width: 112, height: 132)
        .background(LColors.glassSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LColors.glassBorder, lineWidth: 1)
        }
    }
}

func fieldLabel(_ title: String) -> some View {
    Group {
        if !title.isEmpty {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(LColors.textSecondary)
        }
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension View {
    @ViewBuilder
    func lumeyReportAdaptivePresentation<Content: View>(
        isPresented: Binding<Bool>,
        useFullScreenCover: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if useFullScreenCover {
            self.fullScreenCover(isPresented: isPresented, content: content)
        } else {
            self.sheet(isPresented: isPresented, content: content)
        }
    }
}
