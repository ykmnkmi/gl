T unsafeCast<T>(dynamic value) {
  // ignore: return_of_invalid_type
  return value;
}

extension Cast on Object? {
  T as<T>() {
    return unsafeCast<T>(this);
  }
}
