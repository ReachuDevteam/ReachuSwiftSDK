import Foundation
import ReachuCore
import ReachuDesignSystem

@MainActor
extension CartManager {

    @discardableResult
    public func discountCreate(
        code: String,
        percentage: Int,
        startDate: String? = nil,
        endDate: String? = nil,
        typeId: Int = 2
    ) async -> Int? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            logRequest(
                "sdk.discount.add",
                payload: [
                    "code": code,
                    "percentage": percentage,
                    "startDate": startDate as Any,
                    "endDate": endDate as Any,
                    "typeId": typeId
                ]
            )
            let dto = try await sdk.discount.add(
                code: code,
                percentage: percentage,
                startDate: startDate ?? iso8601String(from: Date()),
                endDate: endDate
                    ?? iso8601String(
                        from: Calendar.current.date(
                            byAdding: .day,
                            value: 7,
                            to: Date()
                        )!
                    ),
                typeId: typeId
            )
            logResponse("sdk.discount.add", payload: ["discountId": dto.id as Any])
            let did = dto.id
            lastDiscountId = did
            lastDiscountCode = code
            await MainActor.run {
                ToastManager.shared.showSuccess("Discount created: \(code)")
            }
            return did
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.discount.add", error: error)
            print("❌ [Discount] create FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Create discount failed")
            }
            return nil
        }
    }

    @discardableResult
    public func discountApply(code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else {
            print("ℹ️ [Discount] apply: missing code")
            return false
        }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Discount] apply: missing cartId")
            return false
        }

        do {
            logRequest(
                "sdk.discount.apply",
                payload: ["code": normalized, "cartId": cid]
            )
            let dto: ApplyDiscountDto = try await sdk.discount.apply(
                code: normalized,
                cartId: cid
            )
            logResponse(
                "sdk.discount.apply",
                payload: ["executed": dto.executed, "message": dto.message]
            )

            if dto.executed {
                lastDiscountCode = normalized
                await MainActor.run {
                    ToastManager.shared.showSuccess(
                        dto.message.isEmpty
                            ? "Discount applied: \(normalized)"
                            : dto.message
                    )
                }
                return true
            } else {
                errorMessage = dto.message
                print("⚠️ [Discount] apply NOT EXECUTED (\(normalized)) -> \(dto.message)")
                await MainActor.run {
                    ToastManager.shared.showInfo(
                        dto.message.isEmpty
                            ? "Discount not applied"
                            : dto.message
                    )
                }
                return false
            }

        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.discount.apply", error: error)
            print("❌ [Discount] apply FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Apply discount failed")
            }
            return false
        }
    }

    @discardableResult
    public func discountRemoveApplied(code: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Discount] deleteApplied: missing cartId")
            return false
        }

        let useCode =
            (code ?? lastDiscountCode)?.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            ?? ""
        guard !useCode.isEmpty else {
            print("ℹ️ [Discount] deleteApplied: missing code")
            return false
        }

        do {
            logRequest(
                "sdk.discount.deleteApplied",
                payload: ["code": useCode, "cartId": cid]
            )
            _ = try await sdk.discount.deleteApplied(code: useCode, cartId: cid)
            if lastDiscountCode == useCode { lastDiscountCode = nil }
            await MainActor.run {
                ToastManager.shared.showInfo("Discount removed: \(useCode)")
            }
            return true
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.discount.deleteApplied", error: error)
            print("❌ [Discount] deleteApplied FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Remove discount failed")
            }
            return false
        }
    }

    @discardableResult
    public func discountDelete(discountId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            logRequest("sdk.discount.delete", payload: ["discountId": discountId])
            _ = try await sdk.discount.delete(discountId: discountId)
            if lastDiscountId == discountId { lastDiscountId = nil }
            await MainActor.run {
                ToastManager.shared.showInfo("Discount deleted: \(discountId)")
            }
            return true
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.discount.delete", error: error)
            print("❌ [Discount] delete FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Delete discount failed")
            }
            return false
        }
    }

    @discardableResult
    public func discountGetIdByCode(code: String) async -> Int? {
        let needle = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return nil }

        do {
            logRequest("sdk.discount.getByChannel")
            let channelList = try await sdk.discount.getByChannel()
            logResponse(
                "sdk.discount.getByChannel",
                payload: ["count": channelList.count]
            )
            if let found = channelList.first(where: {
                ($0.code ?? "").caseInsensitiveCompare(needle) == .orderedSame
            }) {
                lastDiscountId = found.id
                lastDiscountCode = found.code
                return found.id
            }

            logRequest("sdk.discount.get")
            let all = try await sdk.discount.get()
            logResponse("sdk.discount.get", payload: ["count": all.count])
            if let found = all.first(where: {
                ($0.code ?? "").caseInsensitiveCompare(needle) == .orderedSame
            }) {
                lastDiscountId = found.id
                lastDiscountCode = found.code
                return found.id
            }
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            print("⚠️ [Discount] get by code '\(code)' FAIL \(msg)")
            logError("sdk.discount.get", error: error)
            errorMessage = msg
        }
        return nil
    }

    @discardableResult
    public func discountApplyOrCreate(
        code: String,
        percentage: Int = 10,
        startDate: String? = nil,
        endDate: String? = nil,
        typeId: Int = 2
    ) async -> Bool {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return false }

        if await discountApply(code: normalized) {
            return true
        }

        if await discountGetIdByCode(code: normalized) != nil {
            if await discountApply(code: normalized) { return true }
            return false
        }

        if await discountCreate(
            code: normalized,
            percentage: percentage,
            startDate: startDate,
            endDate: endDate,
            typeId: typeId
        ) != nil {
            return await discountApply(code: normalized)
        }

        return false
    }
}
