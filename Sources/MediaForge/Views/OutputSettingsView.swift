import MediaForgeCore
import SwiftUI

struct OutputSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(appState.text("output_settings"))
                .font(.headline)

            Picker(appState.text("conversion_type"), selection: $appState.selectedConversionType) {
                Text(appState.text("video_to_audio")).tag(ConversionType.videoToAudio)
                Text(appState.text("video_to_video")).tag(ConversionType.videoToVideo)
                Text(appState.text("audio_to_audio")).tag(ConversionType.audioToAudio)
            }

            Picker(appState.text("preset"), selection: $appState.selectedPreset) {
                ForEach(appState.availablePresets) { preset in
                    VStack(alignment: .leading) {
                        Text(preset.displayName)
                        Text(preset.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(preset)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appState.text("output_location"))
                    .font(.subheadline.weight(.medium))
                Picker(appState.text("output_location"), selection: outputLocationBinding) {
                    Text(appState.text("source_directory")).tag(OutputChoice.source)
                    Text(appState.text("unified_directory")).tag(OutputChoice.unified)
                }
                .pickerStyle(.segmented)

                if outputLocationBinding.wrappedValue == .unified {
                    HStack {
                        Text(appState.unifiedOutputDirectory?.path ?? appState.text("no_directory"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button(appState.text("choose")) {
                            appState.chooseUnifiedOutputDirectory()
                        }
                    }
                }
            }

            Picker(appState.text("conflict_strategy"), selection: $appState.conflictStrategy) {
                Text(appState.text("auto_rename")).tag(ConflictStrategy.autoRename)
                Text(appState.text("skip")).tag(ConflictStrategy.skip)
                Text(appState.text("overwrite")).tag(ConflictStrategy.overwrite)
            }

            Toggle(appState.text("open_when_done"), isOn: $appState.openOutputDirectoryWhenDone)

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        showAdvanced.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .frame(width: 12)
                        Text(appState.text("advanced_options"))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showAdvanced {
                VStack(alignment: .leading, spacing: 10) {
                    TextField(appState.text("audio_bitrate"), text: optionalString($appState.advancedOptions.audioBitrate))
                    HStack {
                        Text(appState.text("sample_rate"))
                        Spacer()
                        TextField("例如 16000", value: $appState.advancedOptions.sampleRate, format: .number)
                            .frame(width: 90)
                    }
                    HStack {
                        Text(appState.text("channels"))
                        Spacer()
                        Stepper("\(appState.advancedOptions.channels ?? 0)", value: optionalInt($appState.advancedOptions.channels), in: 0...8)
                            .frame(width: 140)
                    }
                    if appState.selectedConversionType == .videoToVideo {
                        TextField(appState.text("video_encoder"), text: optionalString($appState.advancedOptions.videoEncoder))
                        HStack {
                            Text("CRF")
                            Spacer()
                            TextField("例如 23", value: $appState.advancedOptions.crf, format: .number)
                                .frame(width: 90)
                        }
                        TextField(appState.text("video_bitrate"), text: optionalString($appState.advancedOptions.videoBitrate))
                    }
                }
                .padding(.top, 8)
                }
            }

            Spacer()

            HStack {
                Button(appState.text("cancel")) {
                    appState.cancelAll()
                }
                .disabled(!appState.isConverting)

                Button(appState.isConverting ? appState.text("working") : appState.text("start")) {
                    appState.startConversion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.files.isEmpty || appState.isConverting)
            }
        }
        .padding(16)
    }

    private enum OutputChoice: Hashable {
        case source
        case unified
    }

    private var outputLocationBinding: Binding<OutputChoice> {
        Binding {
            if case .unifiedDirectory = appState.outputLocation {
                return .unified
            }
            return .source
        } set: { choice in
            switch choice {
            case .source:
                appState.useSourceDirectoryOutput()
            case .unified:
                if let directory = appState.unifiedOutputDirectory {
                    appState.outputLocation = .unifiedDirectory(directory)
                } else {
                    appState.chooseUnifiedOutputDirectory()
                }
            }
        }
    }

    private func optionalString(_ binding: Binding<String?>) -> Binding<String> {
        Binding {
            binding.wrappedValue ?? ""
        } set: { value in
            binding.wrappedValue = value.isEmpty ? nil : value
        }
    }

    private func optionalInt(_ binding: Binding<Int?>) -> Binding<Int> {
        Binding {
            binding.wrappedValue ?? 0
        } set: { value in
            binding.wrappedValue = value == 0 ? nil : value
        }
    }
}
