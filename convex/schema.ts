import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    userId: v.string(),
    username: v.string(),
    profilePicture: v.optional(v.string()),
    score: v.number(),
    gamesPlayed: v.number(),
    createdAt: v.number(),
  }).index("by_userId", ["userId"]),

  gameProgress: defineTable({
    userId: v.string(),
    gameId: v.string(),
    status: v.union(v.literal("not_started"), v.literal("in_progress"), v.literal("completed")),
    currentLevel: v.number(),
    score: v.number(),
    startedAt: v.number(),
    completedAt: v.optional(v.number()),
  })
  .index("by_userId", ["userId"])
  .index("by_gameId", ["gameId"])
  .index("by_userId_and_gameId", ["userId", "gameId"]),

  games: defineTable({
    gameId: v.string(),
    name: v.string(),
    description: v.string(),
    levels: v.number(),
    maxScore: v.number(),
    isActive: v.boolean(),
    order: v.number(),
  }).index("by_order", ["order"]),
}); 