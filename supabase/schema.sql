-- Extensions
create extension if not exists pgcrypto with schema public;

-- Tables
create table if not exists public.shops (
  id text primary key,
  name text not null
);

create table if not exists public.segments (
  id int primary key,
  title text not null
);

create table if not exists public.shop_stock (
  id uuid primary key default gen_random_uuid(),
  shop_id text not null references public.shops(id) on delete cascade,
  segment_id int not null references public.segments(id) on delete cascade,
  remaining int not null,
  unique (shop_id, segment_id)
);

create table if not exists public.wins (
  id uuid primary key default gen_random_uuid(),
  shop_id text not null references public.shops(id) on delete cascade,
  segment_id int not null references public.segments(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Basic seed (optional)
insert into public.segments(id, title) values
  (1, 'BOB') on conflict do nothing,
  (2, 'BRUMISATEUR') on conflict do nothing,
  (3, 'SAC BANANE') on conflict do nothing;

-- Sample shops (optional)
-- insert into public.shops(id, name) values ('shop-1', 'Boutique 1') on conflict do nothing;
-- insert into public.shop_stock(shop_id, segment_id, remaining)
--   values ('shop-1', 1, 1500), ('shop-1', 2, 350), ('shop-1', 3, 300)
-- on conflict (shop_id, segment_id) do update set remaining = excluded.remaining;

-- RPC for atomic decrement
create or replace function public.decrement_stock(p_shop text, p_segment int)
returns int
language plpgsql
security definer
as $$
declare new_remaining int;
begin
  update public.shop_stock
     set remaining = remaining - 1
   where shop_id = p_shop
     and segment_id = p_segment
     and remaining > 0
  returning remaining into new_remaining;

  if new_remaining is null then
    raise exception 'OUT_OF_STOCK';
  end if;

  insert into public.wins(shop_id, segment_id) values (p_shop, p_segment);
  return new_remaining;
end;
$$;

-- RLS
alter table public.shop_stock enable row level security;
alter table public.wins enable row level security;

-- Minimal policies (read via service role only; keep locked down)
drop policy if exists shop_stock_select on public.shop_stock;
create policy shop_stock_select on public.shop_stock for select to authenticated, anon using (false);

drop policy if exists wins_select on public.wins;
create policy wins_select on public.wins for select to authenticated, anon using (false);


