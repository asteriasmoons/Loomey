import PhotosUI
import SwiftData
import SwiftUI

struct LumeyBetaFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState

    @State private var title = ""
    @State private var area = "General"
    @State private var overallExperience = "Good"
    @State private var testedWhat = ""
    @State private var workedWell = ""
    @State private var couldBeBetter = ""
    @State private var unexpected = ""
    @State private var additionalThoughts = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachmentData: [Data] = []
    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var submittedReportID: String?

    private let areas = LumeyReportFormOptions.areas
    private let overallExperiences = ["Excellent", "Good", "Okay", "Poor"]

    private var canSubmit: Bool {
        !title.trimmed.isEmpty &&
        !area.trimmed.isEmpty &&
        !overallExperience.trimmed.isEmpty &&
        !testedWhat.trimmed.isEmpty &&
        !isSubmitting
    }

    var body: some View {
        LumeyReportFormScaffold {
            LumeyReportHeader(
                eyebrow: "VOXIVERSE",
                title: "Beta Feedback",
                eyebrowColor: theme.palette.secondaryAccent,
                bubbly: true
            ) {
                dismiss()
            }
            LumeyReportInfoCard(
                title: "Send beta feedback to Voxiverse",
                message: "Share what you tested, what worked, and what needs improvement. Loomey will attach the same automatic diagnostics used for reports."
            )
            detailsSection
            testingSection
            LumeyReportAttachmentsPicker(
                title: "Attachments",
                selectedPhotos: $selectedPhotos,
                attachmentData: attachmentData,
                accentColor: theme.palette.secondaryAccent,
                sectionColor: theme.palette.indicators,
                bubbly: true
            )
            LumeyReportDiagnosticsCard(screenName: "Beta Feedback", borderColor: theme.palette.indicators)
            LumeyReportStatusCards(successTitle: "Feedback Sent", reportID: submittedReportID, error: submissionError)
            LumeyReportSubmitButton(
                title: "Submit Beta Feedback",
                sendingTitle: "Sending...",
                canSubmit: canSubmit,
                isSubmitting: isSubmitting,
                bubblyTint: theme.palette.primaryAction
            ) {
                Task { await submitFeedback() }
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadAttachments(from: newItems) }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LumeyReportSectionHeader(title: "Feedback Details", color: theme.palette.primaryAction, bubbly: true)
            LumeyReportTextField(title: "Title", placeholder: "Short summary of the feedback", text: $title, borderColor: theme.palette.secondaryAccent)
            LumeyReportPickerField(title: "Area", options: areas, selection: $area, bubblyTint: theme.palette.primaryAction, textShadow: true)
            LumeyReportPickerField(title: "Overall Experience", options: overallExperiences, selection: $overallExperience, bubblyTint: theme.palette.secondaryAccent, textShadow: true)
        }
    }

    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LumeyReportSectionHeader(title: "Testing Notes", color: theme.palette.secondaryAccent, bubbly: true)
            LumeyReportTextEditor(title: "What Did You Test?", placeholder: "Which feature, workflow, screen, or part of Lumey were you testing?", text: $testedWhat, minHeight: 130, borderColor: theme.palette.indicators)
            LumeyReportTextEditor(title: "What Worked Well?", placeholder: "What felt good, clear, useful, or polished?", text: $workedWell, minHeight: 110, borderColor: theme.palette.primaryAction)
            LumeyReportTextEditor(title: "What Could Be Better?", placeholder: "What felt awkward, confusing, incomplete, slow, or visually off?", text: $couldBeBetter, minHeight: 110, borderColor: theme.palette.secondaryAccent)
            LumeyReportTextEditor(title: "Anything Unexpected?", placeholder: "Anything surprising that was not necessarily a bug?", text: $unexpected, minHeight: 100, borderColor: theme.palette.indicators)
            LumeyReportTextEditor(title: "Additional Thoughts", placeholder: "Anything else you want to share?", text: $additionalThoughts, minHeight: 100, borderColor: theme.palette.primaryAction)
        }
    }

    private func loadAttachments(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items.prefix(3) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        await MainActor.run { attachmentData = loaded }
    }

    @MainActor
    private func submitFeedback() async {
        isSubmitting = true
        submissionError = nil
        submittedReportID = nil

        let payload = VoxiverseBetaFeedbackPayload(
            title: title,
            area: area,
            overallExperience: overallExperience,
            testedWhat: testedWhat,
            workedWell: workedWell,
            couldBeBetter: couldBeBetter,
            unexpected: unexpected,
            additionalThoughts: additionalThoughts,
            attachmentData: attachmentData,
            reporterName: reporterName
        )

        do {
            let result = try await VoxiverseReportSubmissionService.shared.submitBetaFeedback(payload)
            do {
                try saveSubmittedFeedback(reportID: result.reportID, diagnostics: result.diagnostics)
                resetForm()
                dismiss()
            } catch {
                submittedReportID = result.reportID
                submissionError = "The feedback was sent, but its local Submitted copy could not be saved: \(error.localizedDescription)"
                isSubmitting = false
            }
        } catch {
            submissionError = error.localizedDescription
            isSubmitting = false
        }
    }

    @MainActor
    private func resetForm() {
        title = ""
        area = "General"
        overallExperience = "Good"
        testedWhat = ""
        workedWell = ""
        couldBeBetter = ""
        unexpected = ""
        additionalThoughts = ""
        selectedPhotos = []
        attachmentData = []
        submissionError = nil
        submittedReportID = nil
        isSubmitting = false
    }

    @MainActor
    private func saveSubmittedFeedback(reportID: String, diagnostics: LumeyReportDiagnostics) throws {
        let savedAttachments = attachmentData.prefix(3).enumerated().map { index, data in
            SubmittedReportAttachment(displayName: "Screenshot \(index + 1)", imageData: data)
        }
        let report = SubmittedReport(
            reportID: reportID,
            reportType: "Beta Feedback",
            title: title.trimmed,
            descriptionText: testedWhat.trimmed,
            expectedBehavior: "",
            steps: [],
            category: area,
            severity: "",
            frequency: "",
            overallExperience: overallExperience,
            testedWhat: testedWhat.trimmed,
            workedWell: workedWell.trimmed,
            couldBeBetter: couldBeBetter.trimmed,
            unexpected: unexpected.trimmed,
            appName: diagnostics.appName,
            appVersion: diagnostics.appVersion,
            buildNumber: diagnostics.buildNumber,
            bundleIdentifier: diagnostics.bundleIdentifier,
            deviceModel: diagnostics.deviceModel,
            iOSVersion: diagnostics.iOSVersion,
            locale: diagnostics.locale,
            timeZone: diagnostics.timeZone,
            screenName: diagnostics.screenName,
            additionalNotes: additionalThoughts.trimmed,
            submittedAt: diagnostics.submittedAt,
            attachments: savedAttachments
        )
        modelContext.insert(report)
        try modelContext.save()
    }

    private var reporterName: String {
        appState.currentUser?.displayName?.trimmed ?? ""
    }
}
