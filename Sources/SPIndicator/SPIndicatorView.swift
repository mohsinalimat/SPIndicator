// The MIT License (MIT)
// Copyright © 2021 Ivan Vorobei (hello@ivanvorobei.by)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

#if os(iOS)

class SPIndicatorView: UIView {
    
    // MARK: - Properties
    
    open var dismissByDrag: Bool = true {
        didSet {
            setGester()
        }
    }
    
    open var completion: (() -> Void)? = nil
    
    private var gestureRecognizer: UIPanGestureRecognizer?
    private var gesterIsDragging: Bool = false
    private var whenGesterEndShoudHide: Bool = false
    
    // MARK: - Views
    
    open var titleLabel: UILabel?
    open var subtitleLabel: UILabel?
    open var iconView: UIView?
    
    private lazy var backgroundView: UIVisualEffectView = {
        let view: UIVisualEffectView = {
            if #available(iOS 13.0, *) {
                return UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
            } else {
                return UIVisualEffectView(effect: UIBlurEffect(style: .light))
            }
        }()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    weak open var presentWindow: UIWindow? = UIApplication.shared.windows.first
    
    // MARK: - Init
    
    public init(title: String, message: String? = nil, preset: SPIndicatorIconPreset) {
        super.init(frame: CGRect.zero)
        commonInit()
        layout = SPIndicatorLayout(for: preset)
        setTitle(title)
        if let message = message {
            setMessage(message)
        }
        setIcon(for: preset)
    }
    
    public init(title: String, message: String?) {
        super.init(frame: CGRect.zero)
        titleAreaFactor = 1.8
        minimumAreaWidth = 100
        commonInit()
        layout = SPIndicatorLayout.message()
        setTitle(title)
        if let message = message {
            setMessage(message)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        preservesSuperviewLayoutMargins = false
        if #available(iOS 11.0, *) {
            insetsLayoutMarginsFromSafeArea = false
        }
        
        backgroundColor = .clear
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)
        
        setShadow()
        setGester()
    }
    
    // MARK: - Configure
    
    private func setTitle(_ text: String) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .semibold, addPoints: 0)
        label.numberOfLines = 1
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.lineSpacing = 3
        label.attributedText = NSAttributedString(
            string: text, attributes: [.paragraphStyle: style]
        )
        label.textAlignment = .center
        label.textColor = UIColor.Compability.label.withAlphaComponent(0.6)
        titleLabel = label
        addSubview(label)
    }
    
    private func setMessage(_ text: String) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .semibold, addPoints: 0)
        label.numberOfLines = 1
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.lineSpacing = 2
        label.attributedText = NSAttributedString(
            string: text, attributes: [.paragraphStyle: style]
        )
        label.textAlignment = .center
        label.textColor = UIColor.Compability.label.withAlphaComponent(0.3)
        subtitleLabel = label
        addSubview(label)
    }
    
    private func setIcon(for preset: SPIndicatorIconPreset) {
        let view = preset.createView()
        self.iconView = view
        addSubview(view)
    }
    
    private func setShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowOffset = .init(width: 0, height: 7)
        layer.shadowRadius = 40
        
        // Not use render shadow becouse backgorund is visual effect.
        // If turn on it, background will hide.
        // layer.shouldRasterize = true
    }
    
    private func setGester() {
        if dismissByDrag {
            let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            addGestureRecognizer(gestureRecognizer)
            self.gestureRecognizer = gestureRecognizer
        } else {
            self.gestureRecognizer = nil
        }
    }
    
    // MARK: - Present
    
    private var presentAndDismissDuration: TimeInterval = 0.6
    
    open func present(duration: TimeInterval = 1.5, haptic: SPIndicatorHaptic = .success, completion: (() -> Void)? = nil) {
        guard let window = self.presentWindow else { return }
        
        window.addSubview(self)
        
        // Prepare for present
        
        self.whenGesterEndShoudHide = false
        self.completion = completion
        
        isHidden = true
        sizeToFit()
        layoutSubviews()
        center.x = window.frame.midX
        toPresentPosition(.prepare)
        
        // Present
        
        isHidden = false
        haptic.impact()
        UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.toPresentPosition(.visible)
        }, completion: { finished in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                if self.gesterIsDragging {
                    self.whenGesterEndShoudHide = true
                } else {
                    self.dismiss()
                }
            }
        })
        
        if let iconView = self.iconView as? SPIndicatorIconAnimatable {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + presentAndDismissDuration / 3) {
                iconView.animate()
            }
        }
    }
    
    @objc open func dismiss() {
        UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            self.toPresentPosition(.prepare)
        }, completion: { finished in
            self.removeFromSuperview()
            self.completion?()
        })
    }
    
    // MARK: - Internal
    
    private var minimumYTranslationForHideByGester: CGFloat = -10
    private var maxmiumYTranslationByGester: CGFloat = 60
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            self.gesterIsDragging = true
            let translation = gestureRecognizer.translation(in: self)
            let newTranslation: CGFloat = {
                if translation.y <= 0 {
                    return translation.y
                } else {
                    return min(maxmiumYTranslationByGester, translation.y.squareRoot())
                }
            }()
            toPresentPosition(.fromVisible(newTranslation))
        }
        
        if gestureRecognizer.state == .ended {
            gesterIsDragging = false
            
            UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
                if self.whenGesterEndShoudHide {
                    self.toPresentPosition(.prepare)
                } else {
                    let translation = gestureRecognizer.translation(in: self)
                    if translation.y < self.minimumYTranslationForHideByGester {
                        self.toPresentPosition(.prepare)
                    } else {
                        self.toPresentPosition(.visible)
                    }
                }
            }, completion: nil)
        }
    }
    
    private func toPresentPosition(_ position: PresentPosition) {
        switch position {
        case .prepare:
            let position = -((UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0) + 50)
            transform = CGAffineTransform.identity.translatedBy(x: 0, y: position)
        case .visible:
            transform = visibleTranform
        case .fromVisible(let value):
            transform = visibleTranform.translatedBy(x: 0, y: value)
        }
    }
    
    private var visibleTranform: CGAffineTransform {
        var topSafeAreaInsets = (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        if topSafeAreaInsets < 20 { topSafeAreaInsets = 20 }
        let position = topSafeAreaInsets - 3
        return CGAffineTransform.identity.translatedBy(x: 0, y: position)
    }
    
    // MARK: - Layout
    
    open var layout: SPIndicatorLayout = .init()
    
    private var areaHeight: CGFloat = 50
    private var minimumAreaWidth: CGFloat = 196
    private var maximumAreaWidth: CGFloat = 260
    private var titleAreaFactor: CGFloat = 2.5
    private var spaceBetweenTitles: CGFloat = 1
    private var spaceBetweenTitlesAndImage: CGFloat = 16
    
    private var titlesCompactWidth: CGFloat {
        if let iconView = self.iconView {
            let space = iconView.frame.maxY + spaceBetweenTitlesAndImage
            return frame.width - space * 2
        } else {
            return frame.width - layoutMargins.left - layoutMargins.right
        }
    }
    
    private var titlesFullWidth: CGFloat {
        if let iconView = self.iconView {
            let space = iconView.frame.maxY + spaceBetweenTitlesAndImage
            return frame.width - space - layoutMargins.right - self.spaceBetweenTitlesAndImage
        } else {
            return frame.width - layoutMargins.left - layoutMargins.right
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        titleLabel?.sizeToFit()
        let titleWidth: CGFloat = titleLabel?.frame.width ?? 0
        subtitleLabel?.sizeToFit()
        let subtitleWidth: CGFloat = subtitleLabel?.frame.width ?? 0
        var width = (max(titleWidth, subtitleWidth) * titleAreaFactor).rounded()
        
        if width < minimumAreaWidth { width = minimumAreaWidth }
        if width > maximumAreaWidth { width = maximumAreaWidth }
        
        return .init(width: width, height: areaHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = layout.margins
        layer.cornerRadius = frame.height / 2
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = layer.cornerRadius
        
        // Flags
        
        let hasIcon = (self.iconView != nil)
        let hasTitle = (self.titleLabel != nil)
        let hasSubtite = (self.subtitleLabel != nil)
        
        let fitTitleToCompact: Bool = {
            guard let titleLabel = self.titleLabel else { return true }
            titleLabel.numberOfLines = 1
            titleLabel.sizeToFit()
            return titleLabel.frame.width < titlesCompactWidth
        }()
        
        let fitSubtitleToCompact: Bool = {
            guard let subtitleLabel = self.subtitleLabel else { return true }
            subtitleLabel.numberOfLines = 1
            subtitleLabel.sizeToFit()
            return subtitleLabel.frame.width < titlesCompactWidth
        }()
        
        let notFitAnyLabelToCompact: Bool = {
            if !fitTitleToCompact { return true }
            if !fitSubtitleToCompact { return true }
            return false
        }()
        
        var layout: LayoutGrid = .iconTitleCentered
        
        if (hasIcon && hasTitle && hasSubtite) && !notFitAnyLabelToCompact {
            layout = .iconTitleMessageCentered
        }
        
        if (hasIcon && hasTitle && hasSubtite) && notFitAnyLabelToCompact {
            layout = .iconTitleMessageLeading
        }
        
        if (hasIcon && hasTitle && !hasSubtite) {
            layout = .iconTitleCentered
        }
        
        if (!hasIcon && hasTitle && !hasSubtite) {
            layout = .title
        }
        
        if (!hasIcon && hasTitle && hasSubtite) {
            layout = .titleMessage
        }
        
        // Actions
        
        let layoutIcon = { [weak self] in
            guard let self = self else { return }
            guard let iconView = self.iconView else { return }
            iconView.frame = .init(
                origin: .init(x: self.layoutMargins.left, y: iconView.frame.origin.y),
                size: self.layout.iconSize
            )
            iconView.center.y = self.bounds.midY
        }
        
        let layoutTitleCenteredCompact = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            titleLabel.textAlignment = .center
            titleLabel.layoutDynamicHeight(width: self.titlesCompactWidth)
            titleLabel.center.x = self.frame.width / 2
        }
        
        let layoutTitleCenteredFullWidth = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            titleLabel.textAlignment = .center
            titleLabel.layoutDynamicHeight(width: self.titlesFullWidth)
            titleLabel.center.x = self.frame.width / 2
        }
        
        let layoutTitleLeadingFullWidth = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            guard let iconView = self.iconView else { return }
            titleLabel.textAlignment = UIApplication.shared.userInterfaceRightToLeft ? .right : .left
            titleLabel.layoutDynamicHeight(width: self.titlesFullWidth)
            titleLabel.frame.origin.x = self.layoutMargins.left + iconView.frame.width + self.spaceBetweenTitlesAndImage
        }
        
        let layoutSubtitle = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            guard let subtitleLabel = self.subtitleLabel else { return }
            subtitleLabel.textAlignment = titleLabel.textAlignment
            subtitleLabel.layoutDynamicHeight(width: titleLabel.frame.width)
            subtitleLabel.frame.origin.x = titleLabel.frame.origin.x
        }
        
        let layoutTitleSubtitleByVertical = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            guard let subtitleLabel = self.subtitleLabel else {
                titleLabel.center.y = self.bounds.midY
                return
            }
            let allHeight = titleLabel.frame.height + subtitleLabel.frame.height + self.spaceBetweenTitles
            titleLabel.frame.origin.y = (self.frame.height - allHeight) / 2
            subtitleLabel.frame.origin.y = titleLabel.frame.maxY + self.spaceBetweenTitles
        }
        
        // Apply
        
        switch layout {
        case .iconTitleMessageCentered:
            layoutIcon()
            layoutTitleCenteredCompact()
            layoutSubtitle()
        case .iconTitleMessageLeading:
            layoutIcon()
            layoutTitleLeadingFullWidth()
            layoutSubtitle()
        case .iconTitleCentered:
            layoutIcon()
            titleLabel?.numberOfLines = 2
            layoutTitleCenteredCompact()
        case .iconTitleLeading:
            layoutIcon()
            titleLabel?.numberOfLines = 2
            layoutTitleLeadingFullWidth()
        case .title:
            titleLabel?.numberOfLines = 2
            layoutTitleCenteredFullWidth()
        case .titleMessage:
            layoutTitleCenteredFullWidth()
            layoutSubtitle()
        }
        
        layoutTitleSubtitleByVertical()
    }
    
    // MARK: - Models
    
    enum PresentPosition {
        
        case prepare
        case visible
        case fromVisible(_ translation: CGFloat)
    }
    
    enum LayoutGrid {
        
        case iconTitleMessageCentered
        case iconTitleMessageLeading
        case iconTitleCentered
        case iconTitleLeading
        case title
        case titleMessage
    }
}

#endif
