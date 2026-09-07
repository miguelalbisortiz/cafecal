double unitToKg(String? unit) {
  return switch (unit) {
    'arroba' => 12.5,
    'saco' => 70,
    _ => 1,
  };
}
