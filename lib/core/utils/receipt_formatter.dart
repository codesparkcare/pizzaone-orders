import '../../models/order_model.dart';

class ReceiptFormatter {
  static String formatOrder(OrderModel order) {
    final buffer = StringBuffer();
    const divider = '========================================';
    const subDivider = '----------------------------------------';

    buffer.writeln(divider);
    buffer.writeln('             PIZZA ONE');
    buffer.writeln('    Restaurant & Pizzeria Italienne');
    if (order.shopName.isNotEmpty) {
      buffer.writeln('          ${order.shopName.toUpperCase()}');
    }
    if (order.shopAddress.isNotEmpty) {
      buffer.writeln('  ${order.shopAddress}');
    }
    if (order.shopPhone.isNotEmpty) {
      buffer.writeln('  Tél : ${order.shopPhone}');
    }
    buffer.writeln(divider);

    buffer.writeln('COMMANDE : #${order.id}');
    buffer.writeln('DATE     : ${order.formattedTime}');
    buffer.writeln('TYPE     : ${order.orderTypeLabel.toUpperCase()}');
    buffer.writeln('PAIEMENT : ${order.paymentMethod.toUpperCase()}');
    buffer.writeln('STATUT   : ${order.statusLabelFr.toUpperCase()}');
    buffer.writeln(subDivider);

    buffer.writeln('CLIENT :');
    buffer.writeln('Nom      : ${order.customerName}');
    buffer.writeln('Tél      : ${order.customerPhone}');
    if (order.isDelivery && order.customerAddress.isNotEmpty) {
      buffer.writeln('Adresse  : ${order.customerAddress}');
    }
    if (order.notes.isNotEmpty) {
      buffer.writeln('Notes    : ${order.notes}');
    }
    buffer.writeln(divider);

    buffer.writeln('ARTICLES COMMANDE :');
    buffer.writeln(subDivider);

    if (order.items.isEmpty) {
      buffer.writeln('  Détail articles non spécifié');
    } else {
      for (final item in order.items) {
        final lineTotal = item.itemTotal.toStringAsFixed(2);
        buffer.writeln('${item.quantity}x ${item.name}');
        if (item.size.isNotEmpty) {
          buffer.writeln('   Taille: ${item.size}');
        }
        for (final addon in item.addons) {
          buffer.writeln('   + $addon');
        }
        if (item.instructions.isNotEmpty) {
          buffer.writeln('   Note: ${item.instructions}');
        }
        buffer.writeln('                          €$lineTotal');
      }
    }

    buffer.writeln(subDivider);
    buffer.writeln('SOUS-TOTAL :               €${order.subtotal.toStringAsFixed(2)}');
    if (order.isDelivery) {
      buffer.writeln('FRAIS DE LIVRAISON :       €${order.deliveryFee.toStringAsFixed(2)}');
    }
    buffer.writeln(divider);
    buffer.writeln('TOTAL A PAYER :            €${order.totalAmount.toStringAsFixed(2)}');
    buffer.writeln(divider);
    buffer.writeln('');
    buffer.writeln('    Merci pour votre commande !');
    buffer.writeln('     www.pizzaonerestaurant.com');
    buffer.writeln(divider);

    return buffer.toString();
  }
}
