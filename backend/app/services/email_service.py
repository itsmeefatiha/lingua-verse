import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings

logger = logging.getLogger(__name__)

def send_email(to_email: str, subject: str, html_content: str):
    """
    Fonction de base pour envoyer un e-mail via le serveur SMTP.
    """
    # Création du message
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = settings.SMTP_USER
    msg["To"] = to_email

    # Ajout du contenu HTML
    part = MIMEText(html_content, "html")
    msg.attach(part)

    try:
        # Connexion au serveur SMTP
        server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT)
        server.starttls() # Sécurise la connexion
        server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        
        # Envoi de l'e-mail
        server.sendmail(settings.SMTP_USER, to_email, msg.as_string())
        server.quit()
        logger.info(f"Email sent successfully to {to_email}")
        return True
    except smtplib.SMTPAuthenticationError as e:
        logger.error(f"SMTP authentication failed: {e}")
        return False
    except smtplib.SMTPException as e:
        logger.error(f"SMTP error while sending email to {to_email}: {e}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error sending email to {to_email}: {e}", exc_info=True)
        return False


def send_activation_otp_email(email: str, otp_code: str):
    """
    Prépare et envoie l'e-mail d'activation de compte LinguaVerse.
    """
    subject = "Bienvenue sur LinguaVerse ! Activez votre compte"
    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif; color: #1E293B; text-align: center; padding: 20px;">
        <h2 style="color: #7D7AFF;">Bienvenue sur LinguaVerse ! 🌍</h2>
        <p>Merci de vous être inscrit. Pour commencer à apprendre et accéder au Metaverse, veuillez activer votre compte.</p>
        <p>Voici votre code d'activation (valable 15 minutes) :</p>
        <div style="font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #00D8CD; padding: 15px; border: 2px dashed #7D7AFF; display: inline-block; margin: 20px 0;">
            {otp_code}
        </div>
        <p>Si vous n'avez pas créé ce compte, vous pouvez ignorer cet e-mail.</p>
        <p>L'équipe LinguaVerse.</p>
      </body>
    </html>
    """
    send_email(email, subject, html_content)


def send_reset_password_email(email: str, otp_code: str):
    """
    Prépare et envoie l'e-mail de réinitialisation de mot de passe.
    """
    subject = "LinguaVerse - Réinitialisation de votre mot de passe"
    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif; color: #1E293B; text-align: center; padding: 20px;">
        <h2 style="color: #7D7AFF;">Réinitialisation de mot de passe 🔒</h2>
        <p>Vous avez demandé à réinitialiser votre mot de passe sur LinguaVerse.</p>
        <p>Voici votre code de sécurité (valable 15 minutes) :</p>
        <div style="font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #FF3B30; padding: 15px; border: 2px dashed #7D7AFF; display: inline-block; margin: 20px 0;">
            {otp_code}
        </div>
        <p>Ne partagez ce code avec personne.</p>
      </body>
    </html>
    """
    send_email(email, subject, html_content)