'use client';

import { useState } from 'react';
import {
  Plus,
  MoreVertical,
  Mail,
  Shield,
  Trash,
  UserPlus,
  X,
} from 'lucide-react';

import {
  Button,
  Input,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardDescription,
  Badge,
  Alert,
  AlertDescription,
} from '@horse-vision/ui';
import { useAuthStore } from '@/stores/auth';

interface TeamMember {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  status: 'active' | 'pending';
  avatarUrl?: string;
  lastLoginAt?: string;
}

export default function TeamSettingsPage() {
  const { user, organization } = useAuthStore();
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState('analyst');

  // Mock data
  const members: TeamMember[] = [
    {
      id: '1',
      firstName: 'Jean',
      lastName: 'Dupont',
      email: 'jean@example.com',
      role: 'owner',
      status: 'active',
      lastLoginAt: '2024-01-15T10:30:00',
    },
    {
      id: '2',
      firstName: 'Marie',
      lastName: 'Martin',
      email: 'marie@example.com',
      role: 'admin',
      status: 'active',
      lastLoginAt: '2024-01-14T15:00:00',
    },
    {
      id: '3',
      firstName: 'Pierre',
      lastName: 'Dubois',
      email: 'pierre@example.com',
      role: 'veterinarian',
      status: 'active',
      lastLoginAt: '2024-01-13T09:00:00',
    },
    {
      id: '4',
      firstName: '',
      lastName: '',
      email: 'nouveau@example.com',
      role: 'analyst',
      status: 'pending',
    },
  ];

  const getRoleLabel = (role: string) => {
    switch (role) {
      case 'owner':
        return 'Propriétaire';
      case 'admin':
        return 'Administrateur';
      case 'veterinarian':
        return 'Vétérinaire';
      case 'analyst':
        return 'Analyste';
      case 'viewer':
        return 'Lecteur';
      default:
        return role;
    }
  };

  const getRoleBadgeVariant = (role: string) => {
    switch (role) {
      case 'owner':
        return 'default';
      case 'admin':
        return 'secondary';
      case 'veterinarian':
        return 'success';
      default:
        return 'outline';
    }
  };

  const handleInvite = async () => {
    // API call would go here
    console.log('Inviting:', inviteEmail, inviteRole);
    setShowInviteModal(false);
    setInviteEmail('');
    setInviteRole('analyst');
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Équipe</h1>
          <p className="text-muted-foreground">
            Gérez les membres de votre organisation
          </p>
        </div>
        <Button onClick={() => setShowInviteModal(true)}>
          <UserPlus className="w-4 h-4 mr-2" />
          Inviter un membre
        </Button>
      </div>

      {/* Organization Info */}
      <Card>
        <CardHeader>
          <CardTitle>Organisation</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-primary/10 rounded-lg flex items-center justify-center">
              <span className="text-2xl font-bold text-primary">
                {organization?.name?.[0] || 'O'}
              </span>
            </div>
            <div>
              <h3 className="text-lg font-semibold">{organization?.name}</h3>
              <p className="text-sm text-muted-foreground">
                {members.length} membres • Plan{' '}
                <span className="capitalize">{organization?.plan}</span>
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Members List */}
      <Card>
        <CardHeader>
          <CardTitle>Membres ({members.length})</CardTitle>
          <CardDescription>
            Membres actuels et invitations en attente
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="divide-y">
            {members.map((member) => (
              <div
                key={member.id}
                className="flex items-center justify-between py-4"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-muted rounded-full flex items-center justify-center">
                    {member.status === 'pending' ? (
                      <Mail className="w-5 h-5 text-muted-foreground" />
                    ) : (
                      <span className="font-medium">
                        {member.firstName[0]}
                        {member.lastName[0]}
                      </span>
                    )}
                  </div>
                  <div>
                    {member.status === 'pending' ? (
                      <p className="font-medium text-muted-foreground">
                        Invitation en attente
                      </p>
                    ) : (
                      <p className="font-medium">
                        {member.firstName} {member.lastName}
                      </p>
                    )}
                    <p className="text-sm text-muted-foreground">
                      {member.email}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <Badge variant={getRoleBadgeVariant(member.role) as any}>
                    {getRoleLabel(member.role)}
                  </Badge>
                  {member.status === 'pending' && (
                    <Badge variant="warning">En attente</Badge>
                  )}
                  {member.role !== 'owner' && (
                    <Button variant="ghost" size="sm">
                      <MoreVertical className="w-4 h-4" />
                    </Button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Roles Info */}
      <Card>
        <CardHeader>
          <CardTitle>Rôles et permissions</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[
              {
                role: 'owner',
                description:
                  'Accès complet. Peut gérer la facturation et supprimer l\'organisation.',
              },
              {
                role: 'admin',
                description:
                  'Peut gérer les membres, chevaux, analyses et rapports.',
              },
              {
                role: 'veterinarian',
                description:
                  'Peut créer et signer des rapports radiologiques.',
              },
              {
                role: 'analyst',
                description:
                  'Peut créer des analyses et consulter les rapports.',
              },
              {
                role: 'viewer',
                description: 'Accès en lecture seule aux données.',
              },
            ].map((item) => (
              <div
                key={item.role}
                className="flex items-start gap-3 p-3 rounded-lg bg-muted/50"
              >
                <Shield className="w-5 h-5 text-primary mt-0.5" />
                <div>
                  <p className="font-medium">{getRoleLabel(item.role)}</p>
                  <p className="text-sm text-muted-foreground">
                    {item.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Invite Modal */}
      {showInviteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-background rounded-lg shadow-lg w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">Inviter un membre</h2>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowInviteModal(false)}
              >
                <X className="w-4 h-4" />
              </Button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">Email</label>
                <Input
                  type="email"
                  placeholder="nouveau@example.com"
                  value={inviteEmail}
                  onChange={(e) => setInviteEmail(e.target.value)}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Rôle</label>
                <select
                  value={inviteRole}
                  onChange={(e) => setInviteRole(e.target.value)}
                  className="w-full h-10 rounded-md border border-input bg-background px-3"
                >
                  <option value="admin">Administrateur</option>
                  <option value="veterinarian">Vétérinaire</option>
                  <option value="analyst">Analyste</option>
                  <option value="viewer">Lecteur</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <Button
                variant="outline"
                onClick={() => setShowInviteModal(false)}
              >
                Annuler
              </Button>
              <Button onClick={handleInvite} disabled={!inviteEmail}>
                <Mail className="w-4 h-4 mr-2" />
                Envoyer l'invitation
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
