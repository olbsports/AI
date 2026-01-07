import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private readonly configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get('SMTP_HOST', 'localhost'),
      port: this.configService.get('SMTP_PORT', 1025),
      secure: this.configService.get('SMTP_SECURE', false),
      auth:
        this.configService.get('SMTP_USER') &&
        this.configService.get('SMTP_PASS')
          ? {
              user: this.configService.get('SMTP_USER'),
              pass: this.configService.get('SMTP_PASS'),
            }
          : undefined,
    });
  }

  async sendEmail(options: EmailOptions): Promise<void> {
    try {
      const from = this.configService.get(
        'EMAIL_FROM',
        'Horse Tempo <noreply@horsetempo.app>',
      );

      await this.transporter.sendMail({
        from,
        to: options.to,
        subject: options.subject,
        html: options.html,
        text: options.text,
      });

      this.logger.log(`Email sent to ${options.to}: ${options.subject}`);
    } catch (error) {
      this.logger.error(`Failed to send email to ${options.to}`, error);
      throw error;
    }
  }

  async sendPasswordResetEmail(
    email: string,
    token: string,
    firstName: string,
  ): Promise<void> {
    const baseUrl = this.configService.get('APP_URL', 'http://localhost:3000');
    const resetUrl = `${baseUrl}/auth/reset-password?token=${token}`;

    await this.sendEmail({
      to: email,
      subject: 'Réinitialisation de votre mot de passe - Horse Tempo',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #1a1a2e; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .button { display: inline-block; padding: 12px 24px; background: #7c3aed; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🐴 Horse Tempo</h1>
            </div>
            <div class="content">
              <h2>Bonjour ${firstName},</h2>
              <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
              <p>Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe :</p>
              <p style="text-align: center;">
                <a href="${resetUrl}" class="button">Réinitialiser mon mot de passe</a>
              </p>
              <p>Ce lien expirera dans 1 heure.</p>
              <p>Si vous n'avez pas demandé cette réinitialisation, vous pouvez ignorer cet email.</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} Horse Tempo. Tous droits réservés.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    });
  }

  async sendVerificationEmail(
    email: string,
    token: string,
    firstName: string,
  ): Promise<void> {
    const baseUrl = this.configService.get('APP_URL', 'http://localhost:3000');
    const verifyUrl = `${baseUrl}/auth/verify-email?token=${token}`;

    await this.sendEmail({
      to: email,
      subject: 'Vérifiez votre adresse email - Horse Tempo',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #1a1a2e; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .button { display: inline-block; padding: 12px 24px; background: #7c3aed; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🐴 Horse Tempo</h1>
            </div>
            <div class="content">
              <h2>Bienvenue ${firstName} !</h2>
              <p>Merci de vous être inscrit sur Horse Tempo.</p>
              <p>Veuillez confirmer votre adresse email en cliquant sur le bouton ci-dessous :</p>
              <p style="text-align: center;">
                <a href="${verifyUrl}" class="button">Vérifier mon email</a>
              </p>
              <p>Ce lien expirera dans 24 heures.</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} Horse Tempo. Tous droits réservés.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    });
  }

  async sendTeamInvitationEmail(
    email: string,
    token: string,
    inviterName: string,
    organizationName: string,
    role: string,
  ): Promise<void> {
    const baseUrl = this.configService.get('APP_URL', 'http://localhost:3000');
    const inviteUrl = `${baseUrl}/auth/accept-invitation?token=${token}`;

    const roleLabels: Record<string, string> = {
      admin: 'Administrateur',
      veterinarian: 'Vétérinaire',
      analyst: 'Analyste',
      viewer: 'Lecteur',
    };

    await this.sendEmail({
      to: email,
      subject: `${inviterName} vous invite à rejoindre ${organizationName} - Horse Tempo`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #1a1a2e; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .button { display: inline-block; padding: 12px 24px; background: #7c3aed; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            .highlight { background: #e0e7ff; padding: 15px; border-radius: 6px; margin: 15px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🐴 Horse Tempo</h1>
            </div>
            <div class="content">
              <h2>Vous êtes invité !</h2>
              <p><strong>${inviterName}</strong> vous invite à rejoindre l'organisation <strong>${organizationName}</strong> sur Horse Tempo.</p>
              <div class="highlight">
                <p><strong>Rôle :</strong> ${roleLabels[role] || role}</p>
                <p><strong>Organisation :</strong> ${organizationName}</p>
              </div>
              <p style="text-align: center;">
                <a href="${inviteUrl}" class="button">Accepter l'invitation</a>
              </p>
              <p>Cette invitation expirera dans 7 jours.</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} Horse Tempo. Tous droits réservés.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    });
  }
}
