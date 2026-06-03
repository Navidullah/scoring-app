-- CreateTable
CREATE TABLE "SyncDocument" (
    "id" TEXT NOT NULL,
    "deviceId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "localId" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SyncDocument_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SyncDocument_deviceId_idx" ON "SyncDocument"("deviceId");

-- CreateIndex
CREATE UNIQUE INDEX "SyncDocument_deviceId_type_localId_key" ON "SyncDocument"("deviceId", "type", "localId");
