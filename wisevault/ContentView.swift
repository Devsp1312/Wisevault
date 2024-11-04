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

// Replace the incomplete DashboardView with this complete implementation:
struct DashboardView: View {
    @State private var transactions: [Transaction] = []
    @State private var bills: [Bill] = []
    @State private var showingAddTransaction = false
    @State private var showingAddBill = false
    @State private var newAmount = ""
    @State private var newDescription = ""
    @State private var selectedType = TransactionType.expense
    @State private var isLoading = true
    
    // New Bill form states
    @State private var newBillName = ""
    @State private var newBillAmount = ""
    @State private var newBillDueDate = 1
    @State private var newBillMonthlyRecurrence = true
    
    var balance: Double {
        let transactionBalance = transactions.reduce(0) { total, transaction in
            switch transaction.type {
            case .income:
                return total + transaction.amount
            case .expense:
                return total - transaction.amount
            }
        }
        
        // Subtract paid bills from the balance
        let paidBillsTotal = bills.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
        return transactionBalance - paidBillsTotal
    }
    
    var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        let transactionExpenses = transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        let paidBillsTotal = bills.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
        return transactionExpenses + paidBillsTotal + unpaidBillsTotal
    }
    
    var unpaidBillsTotal: Double {
        bills.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
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
    
    var billsSectionHeader: some View {
        HStack {
            Text("Upcoming Bills")
                .font(.headline)
            Spacer()
            Button(action: {
                showingAddBill = true
            }) {
                Image(systemName: "plus.circle")
            }
        }
    }
    
    var billsListView: some View {
        Group {
            if bills.isEmpty {
                Text("No bills added yet")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(bills.sorted { $0.dueDate < $1.dueDate }) { bill in
                            BillCard(
                                bill: bill,
                                togglePaid: {
                                    withAnimation {
                                        if let index = bills.firstIndex(where: { $0.id == bill.id }) {
                                            bills[index].isPaid.toggle()
                                            
                                            // Add transaction when bill is marked as paid
                                            if bills[index].isPaid {
                                                let transaction = Transaction(
                                                    amount: bill.amount,
                                                    description: "Bill Payment: \(bill.name)",
                                                    type: .expense,
                                                    date: Date()
                                                )
                                                transactions.append(transaction)
                                            } else {
                                                // Remove the transaction if bill is marked unpaid
                                                if let transactionIndex = transactions.firstIndex(where: { 
                                                    $0.description == "Bill Payment: \(bill.name)" 
                                                }) {
                                                    transactions.remove(at: transactionIndex)
                                                }
                                            }
                                        }
                                    }
                                },
                                bills: $bills
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    var billsSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            billsSectionHeader
            billsListView
            Text("Remaining to fund: $\(unpaidBillsTotal, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    balanceCardView
                    billsSectionView
                    
                    // Transactions List
                    VStack(alignment: .leading) {
                        Text("Transactions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(transactions) { transaction in
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
                    .padding(.vertical)
                }
            }
            .navigationTitle("WiseVault")
            .toolbar {
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
                                transactions.append(transaction)
                                showingAddTransaction = false
                                newAmount = ""
                                newDescription = ""
                            }
                        }
                    )
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
                                bills.append(bill)
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
    
    private func deleteTransactions(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
    }
}

// Create new ContentView with TabView
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
