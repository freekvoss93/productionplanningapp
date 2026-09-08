-- Petitie-app: databaseschema + Row Level Security (RLS)
--
-- Voer dit EENMALIG uit in de Supabase SQL Editor van je project
-- (Project moet in regio EU / Frankfurt staan i.v.m. AVG).
-- Het is veilig om dit script opnieuw te draaien (create/alter zijn idempotent).

create extension if not exists pgcrypto;

-- Handtekeningen. Bevat het e-mailadres (bijzondere persoonsgegevens context:
-- een politieke petitie), dus deze tabel is nooit rechtstreeks door bezoekers
-- leesbaar (zie RLS + revokes onderaan).
create table if not exists signatures (
  id uuid primary key default gen_random_uuid(),
  first_name text not null,
  last_name text not null,
  email text not null,
  public_consent boolean not null default false,
  status text not null default 'pending' check (status in ('pending', 'confirmed')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);

-- Eén handtekening per e-mailadres (hoofdletterongevoelig).
create unique index if not exists signatures_email_unique_idx on signatures (lower(email));

-- Tokens voor de bevestigingslink en de verwijderlink.
-- We slaan nooit de ruwe token op, alleen een hash daarvan (sha-256, door de
-- serverkant berekend) zodat een eventuele database-lek geen bruikbare
-- tokens oplevert.
create table if not exists signature_tokens (
  id uuid primary key default gen_random_uuid(),
  signature_id uuid not null references signatures(id) on delete cascade,
  token_hash text not null unique,
  purpose text not null check (purpose in ('confirm', 'delete')),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists signature_tokens_signature_id_idx on signature_tokens (signature_id);

-- Losse tabel voor rate limiting op basis van een gehasht IP-adres
-- (nooit het ruwe IP-adres bewaren).
create table if not exists submission_attempts (
  id bigint generated always as identity primary key,
  ip_hash text not null,
  created_at timestamptz not null default now()
);

create index if not exists submission_attempts_ip_created_idx on submission_attempts (ip_hash, created_at);

-- Row Level Security aanzetten op alle tabellen.
alter table signatures enable row level security;
alter table signature_tokens enable row level security;
alter table submission_attempts enable row level security;

-- Er is met opzet GEEN enkele policy voor de publieke rol (anon) op deze
-- drie tabellen: RLS-aan + geen policy = standaard totaal geen toegang.
-- Schrijven (nieuwe handtekening, tokens aanmaken) en volledig lezen
-- (beheerpagina) gaan uitsluitend via server-side code met de
-- service-role key, die RLS altijd mag omzeilen.
--
-- Deze revokes zijn een extra veiligheidslaag bovenop RLS: zelfs als er
-- per ongeluk ooit een te ruime policy bij komt, blijven directe
-- tabelrechten voor bezoekers alsnog ingetrokken.
revoke all on signatures from anon, authenticated;
revoke all on signature_tokens from anon, authenticated;
revoke all on submission_attempts from anon, authenticated;

-- Publieke "view": uitsluitend voornaam + achternaam van handtekeningen die
-- BEVESTIGD zijn en waarbij checkbox 2 (publiek zichtbaar) is aangevinkt.
-- E-mailadres en status komen hier bewust niet in voor.
create or replace view public_signatures as
  select first_name, last_name
  from signatures
  where status = 'confirmed' and public_consent = true;

grant select on public_signatures to anon;

-- Totaalteller van ALLE bevestigde handtekeningen (dus inclusief mensen
-- die anoniem willen blijven).
create or replace view public_signature_stats as
  select count(*) as confirmed_count
  from signatures
  where status = 'confirmed';

grant select on public_signature_stats to anon;
