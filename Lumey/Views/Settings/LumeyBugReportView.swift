import PhotosUI
import SwiftData
import SwiftUI

struct LumeyBugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var appState: AppState

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var expectedBehavior = ""
    @State private var steps = [""]
    @State private var category = "General"
    @State private var severity = "Medium"
    @State private var frequency = "Every Time"
    @State private var additionalNotes = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var attachmentData: [Data] = []
    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var submittedReportID: String?

    private let categories = LumeyReportFormOptions.areas
    private let severities = ["Low", "Medium", "High", "Critical"]
    private let frequencies = ["Once", "Sometimes", "Often", "Every Time"]

    private var canSubmit: Bool {
        !title.trimmed.isEmpty &&
        !descriptionText.trimmed.isEmpty &&
        steps.contains { !$0.trimmed.isEmpty } &&
        !isSubmitting
    }

    var body: some View {
        LumeyReportFormScaffold {
            LumeyReportHeader(
                eyebrow: "VOXIVERSE",
                title: "Report a Bug",
                eyebrowColor: theme.palette.secondaryAccent,
                bubbly: true
            ) {
                dismiss()
            }
            introCard
            detailsSection
            behaviorSection
            reproductionSection
            attachmentsSection(title: "Attachments")
            diagnosticsCard(screenName: "Settings > Bug Report")
            statusCards(successTitle: "Report Sent", reportID: submittedReportID, error: submissionError)
            submitButton(title: "Submit Bug Report")
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadAttachments(from: newItems) }
        }
    }

    private var introCard: some View {
        LumeyReportInfoCard(
            title: "Send this directly to Voxiverse",
            message: "Describe exactly what happened. Loomey will attach the app version, build, device, iOS version, locale, time zone, and submission time automatically.",
            borderColor: theme.palette.primaryAction
        )
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LumeyReportSectionHeader(title: "Report Details", color: theme.palette.primaryAction, bubbly: true)
            LumeyReportTextField(title: "Title", placeholder: "Short description of the bug", text: $title, borderColor: theme.palette.secondaryAccent)
            LumeyReportPickerField(title: "Area", options: categories, selection: $category, bubblyTint: theme.palette.primaryAction)
            LumeyReportPickerField(title: "Severity", options: severities, selection: $severity, bubblyTint: theme.palette.secondaryAccent)
            LumeyReportPickerField(title: "Frequency", options: frequencies, selection: $frequency, bubblyTint: theme.palette.indicators)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LumeyReportSectionHeader(title: "What Happened", color: theme.palette.secondaryAccent, bubbly: true)
            LumeyReportTextEditor(title: "Description", placeholder: "Tell me what happened, what you were doing, and what went wrong.", text: $descriptionText, minHeight: 150, borderColor: theme.palette.indicators)
            LumeyReportTextEditor(title: "Expected Behavior", placeholder: "What did you expect Loomey to do instead?", text: $expectedBehavior, minHeight: 110, borderColor: theme.palette.primaryAction)
        }
    }

    private var reproductionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LumeyReportSectionHeader(title: "Reproduce the Bug", color: theme.palette.indicators, bubbly: true)
            LumeyReportDynamicStepsField(title: "Steps to Reproduce", steps: $steps, maxSteps: 10, accentColor: theme.palette.secondaryAccent, bubblyNumbers: true)
            LumeyReportTextEditor(title: "Additional Notes", placeholder: "Anything else that might help explain the problem?", text: $additionalNotes, minHeight: 100, borderColor: theme.palette.indicators)
        }
    }

    private func attachmentsSection(title: String) -> some View {
        LumeyReportAttachmentsPicker(title: title, selectedPhotos: $selectedPhotos, attachmentData: attachmentData, accentColor: theme.palette.primaryAction, bubbly: true)
    }

    private func diagnosticsCard(screenName: String) -> some View {
        LumeyReportDiagnosticsCard(screenName: screenName, borderColor: theme.palette.secondaryAccent)
    }

    private func statusCards(successTitle: String, reportID: String?, error: String?) -> some View {
        LumeyReportStatusCards(successTitle: successTitle, reportID: reportID, error: error)
    }

    private func submitButton(title buttonTitle: String) -> some View {
        LumeyReportSubmitButton(
            title: buttonTitle,
            sendingTitle: "Sending...",
            canSubmit: canSubmit,
            isSubmitting: isSubmitting,
            bubblyTint: theme.palette.indicators
        ) {
            Task { await submitReport() }
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
    private func submitReport() async {
        isSubmitting = true
        submissionError = nil
        submittedReportID = nil

        let payload = VoxiverseBugReportPayload(
            title: title,
            description: descriptionText,
            expectedBehavior: expectedBehavior,
            steps: steps,
            category: category,
            severity: severity,
            frequency: frequency,
            additionalNotes: additionalNotes,
            attachmentData: attachmentData,
            reporterName: reporterName
        )

        do {
            let result = try await VoxiverseReportSubmissionService.shared.submitBugReport(payload)
            do {
                try saveSubmittedReport(reportID: result.reportID, diagnostics: result.diagnostics)
                resetForm()
                dismiss()
            } catch {
                submittedReportID = result.reportID
                submissionError = "The report was sent, but its local Submitted copy could not be saved: \(error.localizedDescription)"
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
        descriptionText = ""
        expectedBehavior = ""
        steps = [""]
        category = "General"
        severity = "Medium"
        frequency = "Every Time"
        additionalNotes = ""
        selectedPhotos = []
        attachmentData = []
        submissionError = nil
        submittedReportID = nil
        isSubmitting = false
    }

    @MainActor
    private func saveSubmittedReport(reportID: String, diagnostics: LumeyReportDiagnostics) throws {
        let savedAttachments = attachmentData.prefix(3).enumerated().map { index, data in
            SubmittedReportAttachment(displayName: "Screenshot \(index + 1)", imageData: data)
        }
        let report = SubmittedReport(
            reportID: reportID,
            title: title.trimmed,
            descriptionText: descriptionText.trimmed,
            expectedBehavior: expectedBehavior.trimmed,
            steps: steps.map(\.trimmed).filter { !$0.isEmpty },
            category: category,
            severity: severity,
            frequency: frequency,
            appName: diagnostics.appName,
            appVersion: diagnostics.appVersion,
            buildNumber: diagnostics.buildNumber,
            bundleIdentifier: diagnostics.bundleIdentifier,
            deviceModel: diagnostics.deviceModel,
            iOSVersion: diagnostics.iOSVersion,
            locale: diagnostics.locale,
            timeZone: diagnostics.timeZone,
            screenName: diagnostics.screenName,
            additionalNotes: additionalNotes.trimmed,
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
