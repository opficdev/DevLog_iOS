//
//  CategoryManageFeatureTests.swift
//  PresentationTests
//
//  Created by opfic on 6/11/26.
//

import Testing
import Foundation
import Domain
import PresentationShared
@testable import HomeTab

@MainActor
struct CategoryManageFeatureTests {
    @Test("항목을 누르면 표시 여부가 전환된다")
    func 항목을_누르면_표시_여부가_전환된다() {
        let item = TodoCategoryItem(from: .system(.issue))
        let driver = CategoryManageTestDriver(preferences: [item])

        driver.tapItem(item)

        #expect(driver.preferences.first?.isVisible == false)
    }

    @Test("항목을 이동하면 preferences 순서가 변경된다")
    func 항목을_이동하면_preferences_순서가_변경된다() {
        let issue = TodoCategoryItem(from: .system(.issue))
        let feature = TodoCategoryItem(from: .system(.feature))
        let driver = CategoryManageTestDriver(preferences: [issue, feature])

        driver.moveItem(from: IndexSet(integer: 0), target: 2)

        #expect(driver.preferences.map(\.id) == [feature.id, issue.id])
    }

    @Test("사용자 카테고리 추가를 누르면 카테고리 입력 시트 상태가 생성된다")
    func 사용자_카테고리_추가를_누르면_카테고리_입력_시트_상태가_생성된다() {
        let item = TodoCategoryItem(from: .system(.issue))
        let driver = CategoryManageTestDriver(preferences: [item])

        driver.tapAddUserCategory()

        #expect(driver.categorySheet?.category.name == "")
        #expect(driver.categorySheet?.category.colorHex.count == 7)
        #expect(driver.categorySheet?.preferences == [item])
    }

    @Test("카테고리 이름은 20자로 제한된다")
    func 카테고리_이름은_20자로_제한된다() {
        let driver = CategoryManageTestDriver(preferences: [])

        driver.tapAddUserCategory()
        driver.setCategoryName(String(repeating: "a", count: 25))

        #expect(driver.categorySheet?.category.name == String(repeating: "a", count: 20))
    }

    @Test("새 사용자 카테고리를 저장하면 이름을 trim한 항목이 추가되고 시트가 닫힌다")
    func 새_사용자_카테고리를_저장하면_이름을_trim한_항목이_추가되고_시트가_닫힌다() {
        let driver = CategoryManageTestDriver(preferences: [])

        driver.tapAddUserCategory()
        let colorHex = driver.categorySheet?.category.colorHex
        driver.setCategoryName("  Custom  ")
        driver.tapSaveButton()

        #expect(driver.preferences.count == 1)
        #expect(driver.userCategory(at: 0)?.name == "Custom")
        #expect(driver.userCategory(at: 0)?.colorHex == colorHex)
        #expect(driver.categorySheet == nil)
    }

    @Test("기존 사용자 카테고리를 저장하면 표시 여부를 유지한 채 항목을 교체한다")
    func 기존_사용자_카테고리를_저장하면_표시_여부를_유지한_채_항목을_교체한다() {
        let item = TodoCategoryItem(
            from: .user(
                UserTodoCategory(
                    id: "custom",
                    name: "Old",
                    colorHex: "#111111"
                )
            ),
            isVisible: false
        )
        let driver = CategoryManageTestDriver(preferences: [item])

        driver.tapEditUserCategory(item)
        driver.setCategoryName("New")
        driver.setCategoryColor("#222222")
        driver.tapSaveButton()

        #expect(driver.preferences.count == 1)
        #expect(driver.preferences.first?.isVisible == false)
        #expect(driver.userCategory(at: 0)?.name == "New")
        #expect(driver.userCategory(at: 0)?.colorHex == "#222222")
        #expect(driver.categorySheet == nil)
    }

    @Test("사용자 카테고리 삭제를 확인하면 항목이 제거된다")
    func 사용자_카테고리_삭제를_확인하면_항목이_제거된다() {
        let issue = TodoCategoryItem(from: .system(.issue))
        let item = TodoCategoryItem(
            from: .user(
                UserTodoCategory(
                    id: "custom",
                    name: "Custom",
                    colorHex: "#111111"
                )
            )
        )
        let driver = CategoryManageTestDriver(preferences: [issue, item])

        driver.tapDeleteUserCategory(item)
        driver.confirmDeleteUserCategory(item)

        #expect(driver.preferences.map(\.id) == [SystemTodoCategory.issue.rawValue])
        #expect(driver.alert == nil)
    }

    @Test("삭제 알림을 닫으면 알림 상태가 초기화된다")
    func 삭제_알림을_닫으면_알림_상태가_초기화된다() {
        let item = TodoCategoryItem(
            from: .user(
                UserTodoCategory(
                    id: "custom",
                    name: "Custom",
                    colorHex: "#111111"
                )
            )
        )
        let driver = CategoryManageTestDriver(preferences: [item])

        driver.tapDeleteUserCategory(item)
        driver.dismissAlert()

        #expect(driver.preferences == [item])
        #expect(driver.alert == nil)
    }

    @Test("시트 상태를 액션에 맞게 변경한다")
    func 시트_상태를_액션에_맞게_변경한다() {
        let category = UserTodoCategory(
            id: "custom",
            name: "Custom",
            colorHex: "#111111"
        )
        let sheet = CategoryManageFeature.CategorySheetState(
            category: category,
            preferences: []
        )
        let driver = CategoryManageTestDriver(preferences: [])

        driver.setCategorySheet(sheet)

        #expect(driver.categorySheet == sheet)

        driver.dismissCategorySheet()

        #expect(driver.categorySheet == nil)

        driver.setCategorySheet(sheet)
        driver.tapCloseButton()

        #expect(driver.categorySheet == nil)
    }

    @Test("완료 버튼을 누르면 현재 preferences를 delegate로 전달한다")
    func 완료_버튼을_누르면_현재_preferences를_delegate로_전달한다() async {
        let item = TodoCategoryItem(from: .system(.issue))
        let store = TestStore(
            initialState: CategoryManageFeature.State(preferences: [item])
        ) {
            CategoryManageFeature()
        }

        await store.send(.tapDoneButton)
        await store.receive(.delegate(.done([item])))
    }
}

@MainActor
private struct CategoryManageTestDriver {
    private let feature: StoreOf<CategoryManageFeature>

    var preferences: [TodoCategoryItem] {
        feature.state.preferences
    }

    var categorySheet: CategoryManageFeature.CategorySheetState? {
        feature.state.categorySheet
    }

    var alert: AlertState<CategoryManageFeature.Action.Alert>? {
        feature.state.alert
    }

    init(preferences: [TodoCategoryItem]) {
        feature = Store(
            initialState: CategoryManageFeature.State(preferences: preferences)
        ) {
            CategoryManageFeature()
        }
    }

    func tapItem(_ item: TodoCategoryItem) {
        feature.send(.tapItem(item))
    }

    func moveItem(from source: IndexSet, target: Int) {
        feature.send(.moveItem(from: source, target: target))
    }

    func tapAddUserCategory() {
        feature.send(.tapAddUserCategory)
    }

    func tapEditUserCategory(_ item: TodoCategoryItem) {
        feature.send(.tapEditUserCategory(item))
    }

    func tapDeleteUserCategory(_ item: TodoCategoryItem) {
        feature.send(.tapDeleteUserCategory(item))
    }

    func setCategorySheet(_ sheet: CategoryManageFeature.CategorySheetState?) {
        feature.send(.setCategorySheet(sheet))
    }

    func dismissCategorySheet() {
        feature.send(.categorySheet(.dismiss))
    }

    func setCategoryName(_ name: String) {
        feature.send(.categorySheet(.presented(.binding(.set(\.category.name, name)))))
    }

    func setCategoryColor(_ colorHex: String) {
        feature.send(.categorySheet(.presented(.binding(.set(\.category.colorHex, colorHex)))))
    }

    func tapSaveButton() {
        feature.send(.categorySheet(.presented(.tapSaveButton)))
    }

    func tapCloseButton() {
        feature.send(.categorySheet(.presented(.tapCloseButton)))
    }

    func confirmDeleteUserCategory(_ item: TodoCategoryItem) {
        feature.send(.alert(.presented(.confirmDeleteUserCategory(item))))
    }

    func dismissAlert() {
        feature.send(.alert(.dismiss))
    }

    func userCategory(at index: Int) -> UserTodoCategory? {
        guard case .user(let category) = preferences[index].category else {
            return nil
        }

        return category
    }
}
