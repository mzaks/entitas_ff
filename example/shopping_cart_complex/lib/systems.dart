import 'dart:ui';
import 'package:entitas_ff/entitas_ff.dart';

import 'components.dart';

class CreateProductsSystem extends EntityManagerSystem implements InitSystem {
  @override
  init() {
    Future.delayed(const Duration(milliseconds: 200), (){
      create(int id, String name, Color color, Currency currency, double amount){
        entityManager.createEntity()
        ..set(ProductNameComponent(name))
        ..set(ColorComponent(color))
        ..set(PriceComponent(currency, amount));
      }
      create(42, "Sweater", const Color(0xFF536DFE), Currency.usd, 45.40);
      create(1024, "Socks", const Color(0xFFFFD500), Currency.euro, 8.99);
      create(1337, "Shawl", const Color(0xFF1CE8B5), Currency.usd, 15.30);
      create(123, "Jacket", const Color(0xFFFF6C00), Currency.usd, 145.00);
      create(201805, "Hat", const Color(0xFF574DDD), Currency.euro, 27.90);
      create(128, "Hoodie", const Color(0xFFABD0F2), Currency.usd, 78.21);
      create(321, "Tuxedo", const Color(0xFF8DA0FC), Currency.usd, 1245.90);
      create(1003, "Shirt", const Color(0xFF1CE8B5), Currency.euro, 25.00);
    });
  }
}

class SetupCurrencyConversionSystem extends EntityManagerSystem implements InitSystem {
  @override
  init() {
    entityManager.setUnique(CurrentConversionRateComponent(0.89, 1.12));
    entityManager.setUnique(SelectedCurrencyComponent(Currency.usd));
  }
}

class AddItemToShoppingCartSystem extends ReactiveSystem {
  @override
  executeWith(List<Entity> entities) {
    for (var e in entities) {
      var newCount = (e.getOrNull<CountComponent>()?.value ?? 0) + 1;
      e += CountComponent(newCount);
    }
  }

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [AddToShoppingCartComponent]);
}

class RemoveItemFromShoppingCartSystem extends ReactiveSystem {
  @override
  executeWith(List<Entity> entities) {
    for (var e in entities) {
      final newCount = (e.getOrNull<CountComponent>()?.value ?? 0) - 1;
      if (newCount > 0) {
        e += CountComponent(newCount);
      } else {
        e -= CountComponent;
      }
    }
  }

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [RemoveFromShoppingCartComponent]);
}

class ComputeAmountInSelectedCurrencySystem extends TriggeredSystem {

  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;

  @override
  EntityMatcher get matcher => EntityMatcher(any: [PriceComponent, CurrentConversionRateComponent, SelectedCurrencyComponent]);

  @override
  executeOnChange() {
    var selectedCurrency = entityManager.getUniqueOrNull<SelectedCurrencyComponent>()?.value;
    if (selectedCurrency == null) return;
    var conversionRates = entityManager.getUniqueOrNull<CurrentConversionRateComponent>();
    if (conversionRates == null) return;
    var items = entityManager.group(all: [PriceComponent]);
    for (var item in items.entities) {
      final price = item.getOrNull<PriceComponent>();
      if (price?.currency == selectedCurrency) {
        item += AmountInSelectedCurrencyComponent(price?.amount ?? 0);
      } else {
        final rate = selectedCurrency == Currency.usd ? conversionRates.euroToUsd : conversionRates.usdToEuro;
        item += AmountInSelectedCurrencyComponent(price?.amount ?? 0 * rate);
      }
    }
  }
}

class ComputePriceLabelSystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [AmountInSelectedCurrencyComponent]);

  @override
  executeWith(List<Entity> entities) {
    final currency = entityManager.getUniqueOrNull<SelectedCurrencyComponent>()?.value;
    if ( currency == null) return;
    for (var item in entities) {
      item += PriceLabelComponent(priceLabel(currency, item.get<AmountInSelectedCurrencyComponent>().value));
    }
  }
}

class SwitchCurrencySystem extends ReactiveSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [SwitchCurrencyComponent]);

  @override
  executeWith(List<Entity> entities) {
    final currency = entityManager.getUnique<SelectedCurrencyComponent>().value;
    if ( currency == null) return;
    if (currency == Currency.usd) {
      entityManager.setUnique(SelectedCurrencyComponent(Currency.euro));
    } else {
      entityManager.setUnique(SelectedCurrencyComponent(Currency.usd));
    }
  }

}

class ComputeTotalSumSystem extends TriggeredSystem {

  @override
  GroupChangeEvent get event => GroupChangeEvent.any;

  @override
  EntityMatcher get matcher => EntityMatcher(all:[CountComponent, AmountInSelectedCurrencyComponent]);

  @override
  executeOnChange() {
    final sum = entityManager.group(all: [CountComponent, AmountInSelectedCurrencyComponent]).entities.fold(0.0, (sum, e) => sum
        + (e.getOrNull<AmountInSelectedCurrencyComponent>()?.value ?? 0.0)
            * (e.getOrNull<CountComponent>()?.value ?? 0)
    );
    entityManager.setUnique(TotalAmountComponent(sum));
  }

}

class ComputeTotalSumLabelSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all:[TotalAmountComponent]);

  @override
  executeOnChange() {
    final currency = entityManager.getUnique<SelectedCurrencyComponent>()?.value;
    if (currency == null) return;
    final sum = entityManager.getUnique<TotalAmountComponent>()?.value;
    if (sum == null) return;
    entityManager.setUnique(TotalAmountLabelComponent(priceLabel(currency, sum)));
  }

}

String priceLabel(Currency currency, double amount) {
  switch (currency) {
    case Currency.usd: {
      return "\$" + amount.toStringAsFixed(2);
    }
    case Currency.euro: {
      return amount.toStringAsFixed(2) + "€";
    }
  }
  return "";
}