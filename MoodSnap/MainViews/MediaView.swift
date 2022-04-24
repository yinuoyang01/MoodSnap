import SwiftUI

/**
 View for photo diary sheet.
 */
struct MediaView: View {
    @Environment(\.dismiss) var dismiss
    @State var moodSnap: MoodSnapStruct
    @Binding var data: DataStoreStruct
    @State var image: UIImage? = nil

    var body: some View {
        GroupBox {
            HStack {
                Label(moodSnap.timestamp.dateTimeString(), systemImage: "clock").font(.caption)
                Spacer()
                Button {
                } label: { Image(systemName: "calendar.badge.clock").resizable().scaledToFill().frame(width: 15, height: 15).foregroundColor(Color.primary) }
            }

            ImagePicker(sourceType: .camera, selectedImage: $image)
                .onDisappear(perform: {
                    if image != nil {// put in async main???
                        moodSnap.snapType = .media
                        image!.saveImage(imageName: moodSnap.id.uuidString)
                        if data.settings.saveMediaToCameraRoll {
                            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                        }
                        data.moodSnaps = deleteHistoryItem(moodSnaps: data.moodSnaps, moodSnap: moodSnap)
                        data.moodSnaps.append(moodSnap)
                        data.moodSnaps = sortByDate(moodSnaps: data.moodSnaps)
                        dismiss()
                    }
                })
        }
    }
}
