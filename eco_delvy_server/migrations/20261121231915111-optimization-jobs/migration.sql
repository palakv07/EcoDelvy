BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "optimization_job" (
    "id" bigserial PRIMARY KEY,
    "userIdentifier" text NOT NULL,
    "status" text NOT NULL,
    "solver" text NOT NULL,
    "payloadJson" text NOT NULL,
    "timeLimit" bigint NOT NULL,
    "vehiclePenaltyWeight" double precision,
    "distanceWeight" double precision NOT NULL,
    "mipGap" double precision NOT NULL,
    "resultJson" text,
    "errorMessage" text,
    "createdAt" timestamp without time zone NOT NULL,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "optimization_log" (
    "id" bigserial PRIMARY KEY,
    "jobId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "message" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "optimization_log"
    ADD CONSTRAINT "optimization_log_fk_0"
    FOREIGN KEY("jobId")
    REFERENCES "optimization_job"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR eco_delvy
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('eco_delvy', '20261121231915111-optimization-jobs', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261121231915111-optimization-jobs', "timestamp" = now();

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
