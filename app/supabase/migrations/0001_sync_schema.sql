-- navidrome_stream: esquema de sincronización en la nube (Supabase / PostgreSQL).
--
-- Cada fila pertenece a un usuario de Supabase Auth (auth.users). Row Level
-- Security limita cada operación a las filas con user_id = auth.uid().
--
-- Qué NO se sincroniza (es específico de cada dispositivo o sensible):
--   * relative_path de las descargas: la ruta depende del contenedor de iOS/Android.
--   * session_token y contraseñas: quedan en el Keychain/Keystore del dispositivo.

-- ---------------------------------------------------------------------------
-- Función compartida para mantener updated_at
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Configuración del servidor y preferencias (una fila por usuario)
-- ---------------------------------------------------------------------------
create table if not exists public.server_configs (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  server_url   text not null check (length(server_url) > 0),
  preferences  jsonb not null default '{}'::jsonb,
  updated_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Pistas descargadas (metadatos). Mismo significado que LocalTrack en Dart.
-- ---------------------------------------------------------------------------
create table if not exists public.local_tracks (
  user_id          uuid not null references auth.users (id) on delete cascade,
  track_id         text not null,            -- id de la pista en Navidrome (Subsonic)
  title            text not null,
  artist           text not null,
  album            text not null,
  album_id         text,
  cover_art_id     text,
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  track_number     integer check (track_number is null or track_number > 0),
  suffix           text,                     -- mp3, m4a, flac...
  starred          boolean not null default false,
  downloaded_at    timestamptz not null,
  updated_at       timestamptz not null default now(),
  primary key (user_id, track_id)
);

create index if not exists local_tracks_user_downloaded_idx
  on public.local_tracks (user_id, downloaded_at desc);

-- ---------------------------------------------------------------------------
-- Progreso de audiolibros. Una fila por (usuario, audiolibro).
-- audiobook_id es el id del álbum/audiolibro en Navidrome, sin FK porque
-- los audiolibros viven en el servidor, no en esta base.
-- ---------------------------------------------------------------------------
create table if not exists public.audiobook_progress (
  user_id        uuid not null references auth.users (id) on delete cascade,
  audiobook_id   text not null,
  chapter_index  integer not null default 0 check (chapter_index >= 0),
  position_ms    bigint not null default 0 check (position_ms >= 0),
  completed      boolean not null default false,
  last_played_at timestamptz not null,
  updated_at     timestamptz not null default now(),
  primary key (user_id, audiobook_id)
);

create index if not exists audiobook_progress_user_played_idx
  on public.audiobook_progress (user_id, last_played_at desc);

-- ---------------------------------------------------------------------------
-- Triggers de updated_at
-- ---------------------------------------------------------------------------
create trigger server_configs_set_updated_at
  before update on public.server_configs
  for each row execute function public.set_updated_at();

create trigger local_tracks_set_updated_at
  before update on public.local_tracks
  for each row execute function public.set_updated_at();

create trigger audiobook_progress_set_updated_at
  before update on public.audiobook_progress
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security: cada usuario solo ve y modifica sus propias filas.
-- ---------------------------------------------------------------------------
alter table public.server_configs    enable row level security;
alter table public.local_tracks      enable row level security;
alter table public.audiobook_progress enable row level security;

create policy "server_configs: propietario"
  on public.server_configs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "local_tracks: propietario"
  on public.local_tracks
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "audiobook_progress: propietario"
  on public.audiobook_progress
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
