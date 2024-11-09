//
//  ContentView.swift
//  wisevault
//
//  Created by Dev Patel on 11/4/24.
//

import SwiftUI
import Charts

struct Transaction: Identifiable {
    let id = UUID()
    let amount: Double
    let description: String
    let type: TransactionType
    let date: Date
}

enum TransactionType {
    case income
    case expense
}

struct Bill: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let dueDate: Int // Day of month (1-31)
    var isPaid: Bool
    var monthlyRecurrence: Bool = true
}

struct Budget: Identifiable {
    let id = UUID()
    var monthlyLimit: Double
    var spent: Double
    var savingsGoal: Double
    var savedAmount: Double
}

struct BillCard: View {
    let bill: Bill
    let togglePaid: () -> Void
    @Binding var bills: [Bill]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bill.name)
                .font(.headline)
            
            Text("$\(bill.amount, specifier: "%.2f")")
                .font(.subheadline)
            
            Text("Due: \(bill.dueDate.ordinal) of month")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: togglePaid) {
                HStack {
                    Image(systemName: bill.isPaid ? "checkmark.circle.fill" : "circle")
                    Text(bill.isPaid ? "Paid" : "Mark as Paid")
                }
                .foregroundColor(bill.isPaid ? .green : .blue)
            }
        }
        .padding()
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

extension Int {
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// Update the SplashScreen view with better animations
struct SplashScreen: View {
    @State private var isAnimating = false
    @Binding var isLoading: Bool
    @State private var rotation = 0.0
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("WiseVault")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .offset(y: isAnimating ? 0 : 20)
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 5)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue.opacity(0.3))
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(lineWidth: 5)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                        .rotationEffect(Angle(degrees: rotation))
                }
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Dismiss splash screen after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
}

// Add these view structures before ContentView
struct InsightsView: View {
    var body: some View {
        Text("Insights & Reports Coming Soon!")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

// Add this new view structure before ContentView
struct BillsView: View {
    @EnvironmentObject private var sharedData: SharedData
    @State private var showingAddBill = false
    @State private var newBillName = ""
    @State private var newBillAmount = ""
    @State private var newBillDueDate = 1
    @State private var newBillMonthlyRecurrence = true
    
    var unpaidBillsTotal: Double {
        sharedData.bills.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if sharedData.bills.isEmpty {
                        Text("No bills added yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        ForEach(sharedData.bills.sorted { $0.dueDate < $1.dueDate }) { bill in
                            BillCard(
                                bill: bill,
                                togglePaid: {
                                    if let index = sharedData.bills.firstIndex(where: { $0.id == bill.id }) {
                                        sharedData.bills[index].isPaid.toggle()
                                        
                                        // Add transaction when bill is marked as paid
                                        if sharedData.bills[index].isPaid {
                                            let transaction = Transaction(
                                                amount: bill.amount,
                                                description: "Bill Payment: \(bill.name)",
                                                type: .expense,
                                                date: Date()
                                            )
                                            sharedData.transactions.append(transaction)
                                        } else {
                                            // Remove the transaction if bill is marked unpaid
                                            if let transactionIndex = sharedData.transactions.firstIndex(where: { 
                                                $0.description == "Bill Payment: \(bill.name)" 
                                            }) {
                                                sharedData.transactions.remove(at: transactionIndex)
                                            }
                                        }
                                    }
                                },
                                bills: $sharedData.bills
                            )
                        }
                    }
                    
                    Text("Total to fund: $\(unpaidBillsTotal, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Bills")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBill = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddBill) {
                NavigationView {
                    Form {
                        TextField("Amount", text: $newBillAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Bill Name", text: $newBillName)
                        
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: {
                                    var components = Calendar.current.dateComponents([.year, .month], from: Date())
                                    components.day = newBillDueDate
                                    return Calendar.current.date(from: components) ?? Date()
                                },
                                set: { date in
                                    newBillDueDate = Calendar.current.component(.day, from: date)
                                }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .environment(\.calendar, Calendar(identifier: .gregorian))
                        .environment(\.locale, Locale(identifier: "en_US"))
                        
                        Toggle("Monthly Recurrence", isOn: $newBillMonthlyRecurrence)
                    }
                    .navigationTitle("Add Bill")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddBill = false
                        },
                        trailing: Button("Add") {
                            if let amount = Double(newBillAmount), !newBillName.isEmpty {
                                let bill = Bill(
                                    name: newBillName,
                                    amount: amount,
                                    dueDate: newBillDueDate,
                                    isPaid: false,
                                    monthlyRecurrence: newBillMonthlyRecurrence
                                )
                                sharedData.bills.append(bill)
                                showingAddBill = false
                                newBillName = ""
                                newBillAmount = ""
                                newBillDueDate = 1
                            }
                        }
                    )
                }
            }
        }
    }
}

// Replace the incomplete DashboardView with this complete implementation:
struct DashboardView: View {
    @EnvironmentObject private var sharedData: SharedData
    @State private var showingAddTransaction = false
    @State private var newAmount = ""
    @State private var newDescription = ""
    @State private var selectedType = TransactionType.expense
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var budget = Budget(
        monthlyLimit: 2000,
        spent: 0,
        savingsGoal: 5000,
        savedAmount: 0
    )
    
    var balance: Double {
        let transactionBalance = sharedData.transactions.reduce(0) { total, transaction in
            switch transaction.type {
            case .income:
                return total + transaction.amount
            case .expense:
                return total - transaction.amount
            }
        }
        
        // Subtract paid bills from the balance
        let paidBillsTotal = sharedData.bills.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
        return transactionBalance - paidBillsTotal
    }
    
    var totalIncome: Double {
        sharedData.transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        let transactionExpenses = sharedData.transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        // Only include unpaid bills, since paid bills are already in transactions
        let unpaidBillsTotal = sharedData.bills.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
        
        return transactionExpenses + unpaidBillsTotal
    }
    
    var unpaidBillsTotal: Double {
        sharedData.bills.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var totalSpentThisMonth: Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return sharedData.transactions
            .filter { transaction in
                let month = calendar.component(.month, from: transaction.date)
                let year = calendar.component(.year, from: transaction.date)
                return month == currentMonth && 
                       year == currentYear && 
                       transaction.type == .expense
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var balanceCardView: some View {
        VStack(spacing: 8) {
            Text("Current Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("$\(balance, specifier: "%.2f")")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(balance >= 0 ? .green : .red)
            
            Text("After Bills: $\(balance - unpaidBillsTotal, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor((balance - unpaidBillsTotal) >= 0 ? .green : .red)
                .padding(.top, 4)
            
            balanceChartView
            
            balanceSummaryView
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
    }
    
    var balanceChartView: some View {
        Chart {
            SectorMark(
                angle: .value("Amount", totalIncome),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .foregroundStyle(.green)
            .annotation(position: .overlay) {
                Text("Income")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            SectorMark(
                angle: .value("Amount", max(totalExpenses, 0.01)),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .foregroundStyle(.red)
            .annotation(position: .overlay) {
                Text("Expenses")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 200)
        .padding(.top)
    }
    
    var balanceSummaryView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Income")
                    .font(.caption)
                Text("$\(totalIncome, specifier: "%.2f")")
                    .foregroundColor(.green)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Expenses")
                    .font(.caption)
                Text("$\(totalExpenses, specifier: "%.2f")")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    balanceCardView
                    
                    // Remove HStack and bills section, keep only budget
                    BudgetSectionView(
                        budget: Budget(
                            monthlyLimit: budget.monthlyLimit,
                            spent: totalSpentThisMonth,
                            savingsGoal: budget.savingsGoal,
                            savedAmount: totalIncome - totalExpenses
                        ),
                        editableBudget: $budget
                    )
                    .padding(.horizontal)
                    
                    // Transactions list...
                    // Update ForEach to use sharedData.transactions
                    ForEach(sharedData.transactions) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.description)
                                    .fontWeight(.semibold)
                                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(transaction.type == .income ? "+$\(transaction.amount, specifier: "%.2f")" : "-$\(transaction.amount, specifier: "%.2f")")
                                .foregroundColor(transaction.type == .income ? .green : .red)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }
                    .onDelete(perform: deleteTransactions)
                }
            }
            .navigationTitle("WiseVault")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                NavigationView {
                    Form {
                        TextField("Amount", text: $newAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Description", text: $newDescription)
                        
                        Picker("Type", selection: $selectedType) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                    }
                    .navigationTitle("Add Transaction")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddTransaction = false
                        },
                        trailing: Button("Add") {
                            if let amount = Double(newAmount), !newDescription.isEmpty {
                                let transaction = Transaction(
                                    amount: amount,
                                    description: newDescription,
                                    type: selectedType,
                                    date: Date()
                                )
                                sharedData.transactions.append(transaction)
                                showingAddTransaction = false
                                newAmount = ""
                                newDescription = ""
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showingSettings) {
                BudgetSettingsSheet(budget: $budget)
            }
        }
    }
    
    private func deleteTransactions(at offsets: IndexSet) {
        sharedData.transactions.remove(atOffsets: offsets)
    }
}

// Add this new view for editing budget settings
struct BudgetSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var budget: Budget
    @State private var newMonthlyLimit: String
    @State private var newSavingsGoal: String
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("useBiometrics") private var useBiometrics = false
    @AppStorage("currency") private var currency = "USD"
    
    init(budget: Binding<Budget>) {
        self._budget = budget
        self._newMonthlyLimit = State(initialValue: String(budget.wrappedValue.monthlyLimit))
        self._newSavingsGoal = State(initialValue: String(budget.wrappedValue.savingsGoal))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Settings") {
                    TextField("Monthly Limit", text: $newMonthlyLimit)
                        .keyboardType(.decimalPad)
                    
                    TextField("Savings Goal", text: $newSavingsGoal)
                        .keyboardType(.decimalPad)
                }
                
                Section("Preferences") {
                    Picker("Currency", selection: $currency) {
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("GBP (£)").tag("GBP")
                        Text("JPY (¥)").tag("JPY")
                    }
                    
                    Toggle("Use Face ID / Touch ID", isOn: $useBiometrics)
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        // TODO: Implement data export
                    }
                    
                    Button("Clear All Data") {
                        // TODO: Implement data clearing with confirmation
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
                    
                    Link("Terms of Service", destination: URL(string: "https://yourapp.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if let monthlyLimit = Double(newMonthlyLimit),
                       let savingsGoal = Double(newSavingsGoal) {
                        budget.monthlyLimit = monthlyLimit
                        budget.savingsGoal = savingsGoal
                        dismiss()
                    }
                }
            )
        }
    }
}

// Update the BudgetSectionView
struct BudgetSectionView: View {
    let budget: Budget
    @Binding var editableBudget: Budget
    @State private var showingSettings = false
    
    var spendingProgress: Double {
        min(budget.spent / budget.monthlyLimit, 1.0)
    }
    
    var savingsProgress: Double {
        min(budget.savedAmount / budget.savingsGoal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Overview")
                .font(.headline)
            
            // Monthly Spending Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Monthly")
                    Spacer()
                    Text("$\(budget.spent, specifier: "%.2f")")
                        .foregroundColor(spendingProgress >= 0.9 ? .red : .primary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 12)
                            .opacity(0.1)
                            .foregroundColor(.blue)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * spendingProgress, height: 12)
                            .foregroundColor(spendingProgress >= 0.9 ? .red : .blue)
                    }
                    .cornerRadius(6)
                }
                .frame(height: 12)
                
                Text("Limit: $\(budget.monthlyLimit, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Savings Goal Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Savings")
                    Spacer()
                    Text("$\(budget.savedAmount, specifier: "%.2f")")
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 12)
                            .opacity(0.1)
                            .foregroundColor(.green)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * savingsProgress, height: 12)
                            .foregroundColor(.green)
                    }
                    .cornerRadius(6)
                }
                .frame(height: 12)
                
                Text("Goal: $\(budget.savingsGoal, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
// First, create a class to share data between views
class SharedData: ObservableObject {
    @Published var bills: [Bill] = []
    @Published var transactions: [Transaction] = []
}
// Create new ContentView with TabView
struct ContentView: View {
    @StateObject private var sharedData = SharedData()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(sharedData)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            BillsView()
                .environmentObject(sharedData)
                .tabItem {
                    Label("Bills", systemImage: "dollarsign.circle.fill")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
    }
}
#Preview {
    ContentView()
}
