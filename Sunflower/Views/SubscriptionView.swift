import SwiftUI
import StoreKit
import RevenueCat
import Lottie

struct SubscriptionView: View {
    // MARK: - Properties
    @EnvironmentObject
    private var subscriptionsManager: SubscriptionsManager

    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer?
    @EnvironmentObject
    private var userInfo: UserInfo
    let isFirst: Bool
    let isForce: Bool
    let onClose: () -> Void

    // MARK: - State
    @State private var isPresentedManageSubscription = false
    @State private var isPresentedOffer = false
    @State private var selectedPackage: Package?
    @State private var isPulsing = false

    @State private var isNavigationBarVisible = false
    @State private var isFeaturesVisible = false
    @State private var isSubscriptionsVisible = false

    // MARK: - Body
    var body: some View {
        VStack {
            if let offerings = subscriptionsManager.offerings?.current {
                contentView(offerings: offerings)
            } else {
                loadingView
            }
        }
        .padding(10)
        .background(AppColors.backgroundLight.color)
        .onAppear(perform: setupView)
        .onChange(of: subscriptionsManager.offerings) {_, _ in setupView() }
        .offerCodeRedemption(isPresented: $isPresentedOffer) { result in
            switch result {
            case .success:
                Task {
                    await subscriptionsManager.fetchProducts()
                }
            case .failure:
                print("ERROR")
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .manageSubscriptionsSheet(isPresented: $isPresentedManageSubscription)
    }

    // MARK: - Subviews
    private func contentView(offerings: Offering) -> some View {
        VStack {
            navigationBar
                .opacity(isNavigationBarVisible ? 1 : 0)
                .offset(y: isNavigationBarVisible ? 0 : -20)
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: isNavigationBarVisible)
            Spacer()
            featuresView
                .opacity(isFeaturesVisible ? 1 : 0)
                .scaleEffect(isFeaturesVisible ? 1 : 0.8)
                .animation(.easeInOut(duration: 0.5).delay(0.4), value: isFeaturesVisible)
            VStack(spacing: 2.5) {
                productListView
                Spacer()
                purchaseSection
            }
            .opacity(isSubscriptionsVisible ? 1 : 0)
            .scaleEffect(isSubscriptionsVisible ? 1 : 0.8)
            .animation(.easeInOut(duration: 0.5).delay(0.6), value: isSubscriptionsVisible)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private var navigationBar: some View {
        HStack {
            Text(isFirst && !isForce ? "TRY 3 DAYS FOR FREE WITHOUT PAYING! 🌻" : "Take Care of \nYour Sunflower 🌻")
                .foregroundStyle(AppColors.green.color)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            Spacer()
            if !isForce {
                closeButton
            }
        }
        .padding()
        .background(AppColors.backgroundLight.color)
        .cornerRadius(10)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .padding()
                .clipShape(Circle())
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.green.color)
        }
    }

    private var featuresView: some View {
        HStack(spacing: 5) {
            LottieView(animation: .named("SunflowerMain"))
                .playing(loopMode: .playOnce)
                .frame(width: UIScreen.main.bounds.width * 0.3, height: 200)
            VStack {
                featureItem(icon: "checkmark.circle", text: "Unlimited access to the Sunflower App")
                featureItem(icon: "checkmark.circle", text: "Complications and Widgets")
                featureItem(icon: "checkmark.circle", text: "Watch App support")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cornerRadius(10)
    }

    private func featureItem(icon: String, text: String) -> some View {
        HStack(alignment: .center) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(AppColors.green.color)
    }

    private var productListView: some View {
        VStack {
            if subscriptionsManager.proType == .subscription {
                activeSubscriptionView
            } else {
                availablePackagesView
            }
        }
        .padding()
        .cornerRadius(10)
    }

    private var activeSubscriptionView: some View {
        VStack {
            HStack {
                Text("Subscription is active")
                    .foregroundStyle(AppColors.green.color)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                Spacer()
                Button("Manage subscriptions") {
                    isPresentedManageSubscription = true
                }
            }.padding(.bottom, 10)

            if let middlePackage = subscriptionsManager.offerings?.current?.availablePackages.middle {
                SubscriptionItemPackageView(
                    package: middlePackage,
                    selectedPackage: $selectedPackage,
                    isPromoOffer: false
                )
                .onAppear {
                    selectedPackage = middlePackage
                }
            }
        }
    }

    private var availablePackagesView: some View {
        let packages = subscriptionsManager.offerings?.current?.availablePackages ?? []
        let yearlyOffer = packages[0]
        let allTimeOffer = packages[1]
        let limitedTimeOffer = packages[2]

        return VStack(spacing: 20) {
            if let promoOfferStartDate = userInfo.promoOfferStartDateValue,
               promoOfferStartDate.daysSinceNow() ?? 0 < 1
            {
                VStack(spacing: 10) {
                    specialOfferView(startDate: promoOfferStartDate)

                    // Old All-Time Offer (crossed out)
                    SubscriptionItemPackageView(
                        package: allTimeOffer,
                        selectedPackage: .constant(nil),
                        isPromoOffer: false,
                        isCrossedOut: true
                    )

                    // New Limited Time Offer (selected)
                    SubscriptionItemPackageView(
                        package: limitedTimeOffer,
                        selectedPackage: $selectedPackage,
                        isPromoOffer: true,
                        isCrossedOut: false
                    )

                    Spacer()
                    SubscriptionItemPackageView(
                        package: yearlyOffer,
                        selectedPackage: $selectedPackage,
                        isPromoOffer: false
                    )
                }
                .onAppear {
                    selectedPackage = limitedTimeOffer
                }
            } else {
                // Regular display when no promo is active
                ForEach(packages.dropLast(), id: \.self) { package in
                    SubscriptionItemPackageView(
                        package: package,
                        selectedPackage: $selectedPackage,
                        isPromoOffer: false
                    )
                }
            }
        }
    }

    private func specialOfferView(startDate: Date) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("LIMITED TIME!")
                    .font(.headline)
                    .foregroundColor(AppColors.green.color)
                Spacer()
                Text(timeString(from: remainingTime))
                    .font(.headline)
                    .foregroundColor(AppColors.green.color)
            }
            .padding()
            .background(AppColors.backgroundLight.color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.green.color, lineWidth: 2)
            )
        }
        .onAppear {
            updateRemainingTime(startDate: startDate)
            startTimer(startDate: startDate)
        }
    }

    private func setupView() {
        if let offerings = subscriptionsManager.offerings?.current {
            if let promoOfferStartDate = userInfo.promoOfferStartDateValue,
               let lastPackage = offerings.availablePackages.last {
                selectedPackage = lastPackage
                updateRemainingTime(startDate: promoOfferStartDate)
                startTimer(startDate: promoOfferStartDate)
            } else if let firstPackage = offerings.availablePackages.first {
                selectedPackage = firstPackage
            }
        }
        animateElements()
    }

    private func updateRemainingTime(startDate: Date) {
        let endDate = startDate.addingTimeInterval(24 * 60 * 60) // 24 hours
        remainingTime = max(0, endDate.timeIntervalSince(Date()))
    }

    private func startTimer(startDate: Date) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRemainingTime(startDate: startDate)
            if remainingTime <= 0 {
                timer?.invalidate()
            }
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var purchaseSection: some View {
        VStack(alignment: .center, spacing: 15) {
            purchaseButton
            HStack {
                Spacer()
                Button("Restore Purchases", action: restorePurchases)
                    .font(.caption)
                    .foregroundStyle(AppColors.brown.color)
                Spacer()
                Button("Redeem Code") {
                    isPresentedOffer = true
                }
                .font(.caption)
                .foregroundStyle(AppColors.brown.color)
                Spacer()
            }
        }
    }

    private var purchaseButton: some View {
        Button(action: makePurchase) {
            Text("PURCHASE")
                .frame(width: UIScreen.main.bounds.width * 0.6)
                .padding(5)
        }
        .scaleEffect(isPulsing ? 1.05 : 1.0)
        .animation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear { isPulsing = true }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(selectedPackage == nil)
    }

    private func animateElements() {
        withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
            isNavigationBarVisible = true
        }
        withAnimation(.easeInOut(duration: 0.6).delay(0.6)) {
            isFeaturesVisible = true
        }
        withAnimation(.easeInOut(duration: 0.6).delay(0.9)) {
            isSubscriptionsVisible = true
        }
    }

    private func restorePurchases() {
        Task {
            await subscriptionsManager.restorePurchases()
        }
    }

    private func makePurchase() {
        guard let selectedPackage = selectedPackage else { return }
        Task {
            let result = await subscriptionsManager.buy(package: selectedPackage)
            switch result {
            case .success:
                onClose()
            case .cancel:
                break
            case .failure(let error):
                print(error)
            }
        }
    }
}

struct SubscriptionItemPackageView: View {
    let package: Package
    @Binding var selectedPackage: Package?
    let isPromoOffer: Bool
    var isCrossedOut: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8.5) {
                HStack {
                    Text(package.storeProduct.localizedTitle)
                        .foregroundStyle(isCrossedOut ? AppColors.brown.color : AppColors.green.color)
                        .multilineTextAlignment(.leading)
                        .strikethrough(isCrossedOut)

                    if package.storeProduct.subscriptionPeriod?.unit == .none && !isPromoOffer {
                        Text("| Pay once")
                            .foregroundStyle(AppColors.brown.color)
                            .multilineTextAlignment(.leading)
                            .strikethrough(isCrossedOut)
                    }

                    if isPromoOffer {
                        Text("SPECIAL OFFER")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(AppColors.green.color)
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(package.localizedPriceString)
                    .foregroundStyle(isCrossedOut ? AppColors.brown.color : AppColors.green.color)
                    .multilineTextAlignment(.leading)
                    .strikethrough(isCrossedOut)
                if let localizedPricePerMonth = package.storeProduct.localizedPricePerMonth,
                   package.storeProduct.subscriptionPeriod?.unit == .year {
                    Text("\(localizedPricePerMonth) / month")
                        .foregroundStyle(AppColors.brown.color)
                }
            }
            if !isCrossedOut {
                Image(systemName: selectedPackage == package ? "dot.circle.fill" : "circle")
                    .foregroundColor(selectedPackage == package ? AppColors.green.color : .gray)
            }
        }
        .padding()
        .cornerRadius(10)
        .opacity(selectedPackage == package || isCrossedOut ? 1 : 0.8)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selectedPackage == package ? AppColors.green.color : AppColors.brown.color, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPromoOffer ? AppColors.green.color.opacity(0.1) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: selectedPackage)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCrossedOut {
                withAnimation {
                    selectedPackage = package
                }
            }
        }
    }
}

//// MARK: - Preview
//struct SubscriptionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let subscriptionManager = SubscriptionsManager(isPreview: false, watchManager: WatchManager(), userInfo: UserInfo())
//        subscriptionManager.proType = .subscription
//        return SubscriptionView(isFirst: true, isForce: false, onClose: { })
//            .environmentObject(subscriptionManager)
//            .environmentObject(UserInfo())
//    }
//}

// MARK: - Extensions
extension Array {
    var middle: Element? {
        guard !isEmpty else { return nil }
        return self[count / 2]
    }
}

extension Decimal {
    func decimals(_ nbr: Int) -> String {
        formatted(.number.precision(.fractionLength(nbr)))
    }
}
