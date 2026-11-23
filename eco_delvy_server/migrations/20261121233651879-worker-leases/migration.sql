BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "optimization_job" ADD COLUMN "attemptCount" bigint;
ALTER TABLE "optimization_job" ADD COLUMN "leaseExpiresAt" timestamp without time zone;
ALTER TABLE "optimization_job" ADD COLUMN "leaseToken" text;
ALTER TABLE "optimization_job" ADD COLUMN "lastLogSequence" bigint;

--
-- MIGRATION VERSION FOR eco_delvy
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('eco_delvy', '20261121233651879-worker-leases', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261121233651879-worker-leases', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20261015164015382', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261015164015382', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
