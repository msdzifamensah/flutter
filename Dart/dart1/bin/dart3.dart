class BankAccount {
  String owner, number;
  double balance;
  // constructor:
  BankAccount(this.owner, this.number, this.balance);
  // methods:
  double deposit(double amount) => balance += amount;
  double withdraw(double amount) => balance -= amount;
}

// ignore: always_declare_return_types
deposit(double amount) {}

// ignore: always_declare_return_types
main() {
  var ba = BankAccount('John Gates', '075-0623456-72', 1000.0);
  print('Initial balance:\t\t ${ba.balance} \$');
  ba.deposit(250.0);
  print('Balance after deposit:\t\t ${ba.balance} \$');
  ba.withdraw(100.0);
  print('Balance after withdrawal:\t ${ba.balance} \$');
}
