//
//  ApplicationPane.swift
//  Fire
//
//  Created by 虚幻 on 2021/7/17.
//  Copyright © 2021 qwertyyb. All rights reserved.
//

import SwiftUI
import Settings
import Defaults

struct ApplicationSettingItemView: View {
    var settingItem: ApplicationSettingItem
    let onDelete: () -> Void
    let onChange: () -> Void

    private func getDisplayName(_ identifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else {
            return identifier
        }
        let displayName = FileManager.default.displayName(atPath: url.path)
        return "\(displayName)(\(identifier))"
    }

    private func getIcon(_ identifier: String) -> NSImage {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else {
            return NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    var body: some View {
        return VStack {
            HStack(alignment: .center, spacing: 12, content: {
                Image(nsImage: getIcon(settingItem.bundleIdentifier)).resizable().frame(width: 20, height: 20)
                Text(getDisplayName(settingItem.bundleIdentifier)).frame(width: 200, alignment: .leading)
                Spacer()
                Picker("", selection: Binding<InputModeSetting>(get: {
                    settingItem.inputModeSetting
                }, set: { inputModeSetting in
                    settingItem.objectWillChange.send()
                    settingItem.inputModeSetting = inputModeSetting
                    onChange()
                })) {
                    Text("五笔").tag(InputModeSetting.zhhans)
                    Text("英文").tag(InputModeSetting.enUS)
                }
                .frame(width: 80)

                if #available(macOS 11.0, *) {
                    Button {
                        onDelete()
                    } label: {
                        Image(
                            nsImage: NSImage(named: NSImage.stopProgressTemplateName)!)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("删除")
                } else {
                    Button {
                        onDelete()
                    } label: {
                        Image(nsImage: NSImage(named: NSImage.stopProgressTemplateName)!)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }

            })
                .padding(6)
            Spacer().frame(height: 1).background(Color.gray)
        }
    }
}

struct ApplicationPane: View {
    @Default(.keepAppInputMode) private var keepAppInputMode
    @Default(.appSettings) private var appSettings
    @Default(.disableEnMode) private var disableEnMode
    @Default(.appInputModeTipShowTime) private var appInputModeTipShowTime

    private func addApp() {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = FileManager.default.urls(for: .applicationDirectory, in: .systemDomainMask).first
        openPanel.prompt = "选择应用"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.applicationBundle]
        let result = openPanel.runModal()
        if result != NSApplication.ModalResponse.OK { return }
        let selectedPath = openPanel.url!.path
        guard let bundle = Bundle(path: selectedPath) else { return }
        guard let identifier = bundle.bundleIdentifier else { return }

        appSettings[identifier] = ApplicationSettingItem(bundleId: identifier, inputMs: .enUS)
    }
    private func removeApp(_ settingItem: ApplicationSettingItem) {
        appSettings.removeValue(forKey: settingItem.bundleIdentifier)
    }

    var body: some View {
        Settings.Container(contentWidth: 450) {
            Settings.Section(title: "") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("自动切换")
                        Toggle("保持应用最后使用的输入模式", isOn: $keepAppInputMode)
                            .padding(.leading, 12)
                    }
                    HStack {
                        Picker("显示提示", selection: $appInputModeTipShowTime) {
                            Text("仅在变化时显示").tag(AppInputModeTipShowTime.onlyChanged)
                            Text("总是显示").tag(AppInputModeTipShowTime.always)
                            Text("不显示")
                                .tag(AppInputModeTipShowTime.none)
                        }
                        Spacer(minLength: 240)
                    }
                    HStack {
                        Text("应用设置")
                        Button(action: addApp) {
                            HStack(spacing: 0) {
                                Image(nsImage: NSImage(named: NSImage.addTemplateName)!)
                                    .resizable()
                                    .frame(width: 16, height: 16, alignment: .bottom)
                                Text("添加")
                            }
                        }
                        .padding(.leading, 12)
                    }
                    ScrollView(.vertical) {
                        if appSettings.count > 0 {
                            // 按照添加时间排序
                            ForEach(appSettings.values.sorted(by: { a, b in
                                a.createdTimestamp < b.createdTimestamp
                            })) { (settingItem) -> AnyView in
                                AnyView(ApplicationSettingItemView(settingItem: settingItem) {
                                    removeApp(settingItem)
                                } onChange: {
                                    appSettings[settingItem.bundleIdentifier] = settingItem
                                    Defaults[.appSettings] = appSettings
                                })
                            }
                        } else {
                            VStack {
                                Text("添加应用可单独设置该应用下默认使用英文或五笔")
                                    .foregroundColor(Color.gray)
                            }
                            .frame(minHeight: 300)
                        }
                    }
                    .frame(minWidth: 450, minHeight: 320)
                    .background(Color(.sRGB, red: 0.4, green: 0.4, blue: 0.4, opacity: 0.2))
                }
                .disabled(disableEnMode)
            }
        }
    }
}

struct ApplicationPane_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationPane()
    }
}
