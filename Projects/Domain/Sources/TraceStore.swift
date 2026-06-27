import Foundation

/// Combined store surface — a place repository AND a moment repository on one object.
/// ViewModels depend on `any TraceStore` (not a concrete type), so the backing impl is
/// swappable: `InMemoryTraceStore` (Phase 1) → Supabase-backed store (Phase 2).
///
/// (ADR T1.1a: combined protocol chosen over separate injection / type-erasure for P0–P1
/// simplicity; split when the Supabase impl naturally separates place vs moment concerns.)
public protocol TraceStore: PlaceRepository, MomentRepository {}

extension InMemoryTraceStore: TraceStore {}
