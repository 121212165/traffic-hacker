-- Demo seed for the self-contained ModelScope deploy.
-- Applied once at container startup after the Prisma-generated schema.sql.
-- __APP_HOST__ is replaced by start.sh with the studio hostname so the seeded
-- link domain matches the host serving the app.
--
-- Demo login: demo@traffic-hacker.com / Demo2026!

INSERT INTO `User` (`id`, `name`, `email`, `emailVerified`, `passwordHash`, `defaultWorkspace`, `createdAt`)
VALUES (
  'user_demo00000000000000000001',
  'Demo',
  'demo@traffic-hacker.com',
  NOW(3),
  '$2a$12$EWVrvkUs3ssUMLszECLuW.CNwvVvds59IrWQlBmIbhpBid0r4NWpa',
  'demo',
  NOW(3)
);

INSERT INTO `Project` (
  `id`, `name`, `slug`, `plan`, `billingCycleStart`,
  `usageLimit`, `linksLimit`, `domainsLimit`, `tagsLimit`, `foldersLimit`,
  `usersLimit`, `aiLimit`,
  `createdAt`, `updatedAt`, `usageLastChecked`
)
VALUES (
  'ws_demo0000000000000000000001',
  'TrafficHacker Demo',
  'demo',
  'enterprise',
  1,
  1000000, 100000, 100, 100, 100,
  100, 1000,
  NOW(3), NOW(3), NOW(3)
);

INSERT INTO `ProjectUsers` (`id`, `role`, `userId`, `projectId`, `createdAt`, `updatedAt`)
VALUES (
  'pu_demo0000000000000000000001',
  'owner',
  'user_demo00000000000000000001',
  'ws_demo0000000000000000000001',
  NOW(3), NOW(3)
);

INSERT INTO `NotificationPreference` (`id`, `projectUserId`)
VALUES ('np_demo0000000000000000000001', 'pu_demo0000000000000000000001');

INSERT INTO `DefaultDomains` (`id`, `projectId`)
VALUES ('dd_demo0000000000000000000001', 'ws_demo0000000000000000000001');

-- The studio hostname doubles as the workspace's (verified, primary) short
-- link domain; links on it are reachable via the /r/<key> path escape.
INSERT INTO `Domain` (
  `id`, `slug`, `verified`, `primary`, `projectId`,
  `lastChecked`, `createdAt`, `updatedAt`
)
VALUES (
  'dom_demo000000000000000000001',
  '__APP_HOST__',
  1, 1,
  'ws_demo0000000000000000000001',
  NOW(3), NOW(3), NOW(3)
);
