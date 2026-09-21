/**
 * KSIS Domain Types & Parser Contracts
 * Shared between Supabase Edge Functions
 */

export type DisciplineType = 'STT' | 'LAT' | '10T';

export type CoupleCompetitionState = 
  | 'not_published' 
  | 'advanced' 
  | 'eliminated' 
  | 'final_placement';

export interface KSISCompetitionMeta {
  sutazId: number;
  eventName: string;
  categoryName: string;
  discipline: DisciplineType;
  date: string; // ISO YYYY-MM-DD
  place: string | null;
  coupleCount: number;
  season: string; // e.g. "2025/2026"
  isOfficial: boolean;
}

export interface KSISCoupleResult {
  coupleId: number;
  coupleName: string;
  club: string;
  bib: string | null;
  roundName: string; // e.g. "Finále", "Semifinále", "1.kolo"
  placementText: string; // e.g. "3." or "7.-9."
  placement: number | null; // numeric e.g. 3 or 7
  pointsEarned: number;
  cumulativeStats: string | null; // e.g. "89/5F" (raw string, nullable)
  cumulativePoints: number; // parsed 89
  cumulativeFinals: number; // parsed 5
  isOfficial: boolean;
  state: CoupleCompetitionState;
}

export interface KSISCoupleState {
  meta: KSISCompetitionMeta;
  couple: KSISCoupleResult;
  stateHash: string; // SHA-256 of canonical parsed state
}

export type KSISParseResult = 
  | { status: 'ok'; data: KSISCoupleState }
  | { status: 'blocked'; reason: string }
  | { status: 'not_found'; coupleId: number; totalCouplesOnPage: number }
  | { status: 'not_official'; message: string; meta?: KSISCompetitionMeta };
