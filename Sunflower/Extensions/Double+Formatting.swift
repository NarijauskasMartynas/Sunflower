extension Double {
    var twoDecimals: String {
        String(format: "%.2f", self)
    }

    var withoutDecimal: String {
        String(format: "%.0f", self)
    }
}
