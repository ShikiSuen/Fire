//
//  UserDictPane.swift
//  Fire
//
//  Created by 虚幻 on 2022/7/1.
//  Copyright © 2022 qwertyyb. All rights reserved.
//

import SwiftUI
import Settings
import Combine

class UserDictTextModel: ObservableObject {
    @Published var text = ""
    private var cancellable = Set<AnyCancellable>()

    init() {
        refresh()
        NotificationCenter.default.publisher(for: DictManager.userDictUpdated).sink { _ in
            self.refresh()
        }
        .store(in: &cancellable)
    }

    func refresh() {
        NSLog("[UserDictTextModel.refresh]")
        self.text = DictManager.shared.getUserDictContent()
    }
}

struct UserDictPane: View {
    @StateObject private var userDictTextModel = UserDictTextModel()
    @State private var saved = false
    var body: some View {
        Settings.Container(contentWidth: 450) {
            Settings.Section(title: "") {
                Text("用户词库")
                if #available(macOS 11.0, *) {
                    TextEditor(text: $userDictTextModel.text)
                        .font(Font.custom("Monaco", size: 14))
                        .frame(height: 400)
                        .lineSpacing(6)
                    Text("1. 编码需在行首")
                        .font(Font.system(size: 12))
                    Text("2. 编码和候选项之间需用空格分隔")
                        .font(Font.system(size: 12))
                    Text("3. 可以有多个候选项，每个候选项使用空格分隔")
                        .font(Font.system(size: 12))
                    Text("4. 候选项可使用{yyyy}/{MM}/{dd}/{HH}/{mm}/{ss}代替当前年/月/日/时/分/秒")
                        .font(Font.system(size: 12))
                    HStack {
                        Spacer()
                        if #available(macOS 12.0, *) {
                            Button("保存") {
                                DictManager.shared.updateUserDict(userDictTextModel.text)
                                saved = true
                            }
                            .alert("保存成功", isPresented: $saved) {
                            }
                        } else {
                            // Fallback on earlier versions
                            Button("保存") {
                                DictManager.shared.updateUserDict(userDictTextModel.text)
                                print("saved")
                            }
                        }
                        Spacer()
                    }
                } else {
                    // Fallback on earlier versions
                    Text("暂不支持，请升级系统至11.0及以上")
                }
            }
        }
    }
}

struct UserDictPane_Previews: PreviewProvider {
    static var previews: some View {
        UserDictPane()
    }
}
