/// Marks a list child that is NOT a row — a day / section header. A list that
/// draws hairlines between its rows (`ListPageBody.rowDividers`) leaves a
/// [ListBreak] and its neighbours undivided. Internal to the kit (not
/// exported through ui.dart).
abstract interface class ListBreak {}
