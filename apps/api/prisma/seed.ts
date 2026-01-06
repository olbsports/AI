import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...');

  // Create test organization
  const testOrg = await prisma.organization.upsert({
    where: { slug: 'test-ecurie' },
    update: {},
    create: {
      name: 'Écurie Test',
      slug: 'test-ecurie',
      plan: 'professional',
      tokenBalance: 1000,
    },
  });
  console.log('✅ Test organization created:', testOrg.name);

  // Create admin organization
  const adminOrg = await prisma.organization.upsert({
    where: { slug: 'horsetempo-admin' },
    update: {},
    create: {
      name: 'Horse Tempo Admin',
      slug: 'horsetempo-admin',
      plan: 'enterprise',
      tokenBalance: 999999,
    },
  });
  console.log('✅ Admin organization created:', adminOrg.name);

  // Hash passwords
  const testPassword = await bcrypt.hash('Test1234!', 12);
  const adminPassword = await bcrypt.hash('Admin2024!', 12);

  // Create test user for mobile app
  const testUser = await prisma.user.upsert({
    where: { email: 'test@horsetempo.app' },
    update: {
      passwordHash: testPassword,
      isActive: true,
    },
    create: {
      email: 'test@horsetempo.app',
      passwordHash: testPassword,
      firstName: 'Utilisateur',
      lastName: 'Test',
      role: 'owner',
      isActive: true,
      emailVerified: true,
      organizationId: testOrg.id,
      xp: 500,
      level: 3,
    },
  });
  console.log('✅ Test user created:', testUser.email);

  // Create admin user for admin app
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@horsetempo.app' },
    update: {
      passwordHash: adminPassword,
      isActive: true,
    },
    create: {
      email: 'admin@horsetempo.app',
      passwordHash: adminPassword,
      firstName: 'Admin',
      lastName: 'HorseTempo',
      role: 'admin',
      isActive: true,
      emailVerified: true,
      organizationId: adminOrg.id,
      xp: 10000,
      level: 10,
    },
  });
  console.log('✅ Admin user created:', adminUser.email);

  // Create a demo horse for the test user
  const demoHorse = await prisma.horse.upsert({
    where: { id: 'demo-horse-001' },
    update: {},
    create: {
      id: 'demo-horse-001',
      name: 'Éclipse',
      gender: 'gelding',
      breed: 'Selle Français',
      birthDate: new Date('2018-05-15'),
      heightCm: 168,
      weightKg: 520,
      color: 'Bai',
      disciplines: JSON.stringify(['CSO', 'Dressage']),
      level: 'Amateur',
      status: 'active',
      organizationId: testOrg.id,
    },
  });
  console.log('✅ Demo horse created:', demoHorse.name);

  console.log('\n📋 Summary:');
  console.log('─────────────────────────────────────────');
  console.log('Mobile App (test@horsetempo.app):');
  console.log('  Email: test@horsetempo.app');
  console.log('  Password: Test1234!');
  console.log('');
  console.log('Admin App (admin@horsetempo.app):');
  console.log('  Email: admin@horsetempo.app');
  console.log('  Password: Admin2024!');
  console.log('─────────────────────────────────────────');
  console.log('\n✨ Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
