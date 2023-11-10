//
//  ContentView.swift
//  TestSpeech
//
//  Created by Kostyantin on 15.10.2023.
//
//
import SwiftUI

struct ContentView: View {
    @ObservedObject var speechRec = SpeechRec()
    @State private var isListening = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var itemToShare: URL?

    var body: some View {
        GeometryReader { metrics in
            VStack {
                Text("**MADOK VOICE RECORDER**")
                    .modifier(CustomTextStyle())
                    .padding(.vertical, 30)
                Spacer()
                VStack {
                    if (!isListening) {
                        HStack {
                            Button(action: {
                                self.showingDeleteAlert = true
                            }, label: {
                                Label("Delete all", systemImage: "xmark.circle")
                                    .padding(5)
                            })
                            .foregroundColor(.white)
                            .padding(.top, 10)
                            .actionSheet(isPresented: $showingDeleteAlert) {
                                ActionSheet(title: Text("Delete All Recordings"), message: Text("Are you sure you want to delete all recordings? This action cannot be undone."), buttons: [
                                    .destructive(Text("Delete All")) {
                                        self.speechRec.deleteAllRecordings()
                                    },
                                    .cancel()
                                ])
                            }
                            
                        }
                        
                        List(speechRec.allRecordings(), id: \.self) { url in
                            HStack {
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Button(action: {
                                    self.playRecording(from: url)
                                }) {
                                    Image(systemName: "play.circle")
                                        .imageScale(.large)
                                        .foregroundColor(.blue)
                                }
                                .padding(.trailing, 24)
                                .buttonStyle(BorderlessButtonStyle())
                                Button(action: {
                                    self.itemToShare = url
                                    self.showingShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .imageScale(.large)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.playRecording(from: url)
                            }
                        }
                        .sheet(isPresented: $showingShareSheet, onDismiss: {
                            self.itemToShare = nil
                        }) {
                            if let shareURL = itemToShare {
                                ActivityView(activityItems: [shareURL])
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        Text("Last recording result:")
                        List {
                            Text(speechRec.recognizedText)
                                .padding(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .background(.clear)
                        }
                        .scrollContentBackground(.hidden)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                }
                .modifier(CustomVStackStyle())
                .frame(width: metrics.size.width * 0.90, height: metrics.size.height * 0.5)
                
                Spacer()
                
                Button(action: {
                    if isListening {
                        self.speechRec.stop()
                    } else {
                        self.speechRec.start()
                    }
                    isListening.toggle()
                }) {
                    Text(isListening ? "Stop Listening" : "Start Listening")
                        .modifier(CustomTextStyle())
                }
                .buttonStyle(CustomButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 40)
            .edgesIgnoringSafeArea(.all)
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime), perform: { _ in
                self.itemToShare = nil
            })
            .onAppear {
                self.speechRec.objectWillChange.send()
            }
            .modifier(BackgroundColorStyle())
        }
    }
    
    func playRecording(from url: URL) {
        speechRec.playRecordedAudio(from: url)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}
