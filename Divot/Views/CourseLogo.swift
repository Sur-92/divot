import SwiftUI

/// Course logo badge with a fixed height and variable width derived from
/// the source image's aspect ratio. Falls back to an amber flag icon
/// (square-framed) if no logo asset is available.
struct CourseLogo: View {
    let assetName: String?
    var height: CGFloat = 24
    var corner: CGFloat? = nil

    private var cornerRadius: CGFloat { corner ?? height * 0.18 }

    var body: some View {
        if let assetName, !assetName.isEmpty,
           let img = NSImage(named: assetName) {
            let aspect = img.size.width / max(img.size.height, 1)
            let paddingAmount = height * 0.10
            let contentHeight = height - paddingAmount * 2
            let contentWidth = contentHeight * aspect
            let tileWidth = contentWidth + paddingAmount * 2

            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: contentWidth, height: contentHeight)
                .padding(paddingAmount)
                .frame(width: tileWidth, height: height)
                .background(RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.hairline, lineWidth: 1))
        } else {
            Image(systemName: "flag.fill")
                .font(.system(size: height * 0.55))
                .foregroundStyle(Theme.accent.opacity(0.75))
                .frame(width: height, height: height)
        }
    }
}
