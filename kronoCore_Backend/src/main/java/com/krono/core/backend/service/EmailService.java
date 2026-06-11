package com.krono.core.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.ObjectProvider;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * SERVICIO: EmailService
 * Envía correos de verificación. Si no hay SMTP configurado, deja el enlace en logs.
 */
@Service
public class EmailService {

    private static final Logger logger = Logger.getLogger(EmailService.class.getName());

    private final ObjectProvider<JavaMailSender> mailSenderProvider;

    @Value("${app.frontend-confirmation-url:http://localhost:5500/login/login.html}")
    private String confirmationBaseUrl;

    @Value("${app.frontend-invitation-url:http://localhost:5500/login/login.html}")
    private String invitationBaseUrl;

    public EmailService(ObjectProvider<JavaMailSender> mailSenderProvider) {
        this.mailSenderProvider = mailSenderProvider;
    }

    public String buildConfirmationLink(String token) {
        return confirmationBaseUrl + "?token=" + token;
    }

    public String buildInvitationLink(String token) {
        return invitationBaseUrl + "?invite=" + token;
    }

    public void sendVerificationEmail(String to, String name, String token) {
        String link = buildConfirmationLink(token);
        String subject = "Confirma tu cuenta en KronoCore";
        String text = "Hola " + name + ",\n\n" +
                "Gracias por registrarte en KronoCore.\n" +
                "Confirma tu cuenta haciendo clic en este enlace:\n" +
                link + "\n\n" +
                "Si no solicitaste este registro, puedes ignorar este correo.";

        try {
            JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
            if (mailSender == null) {
                logger.warning("SMTP no configurado. Link de verificacion: " + link);
                return;
            }
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject(subject);
            message.setText(text);
            mailSender.send(message);
        } catch (Exception ex) {
            // Fallback para desarrollo: si no hay SMTP configurado, al menos dejamos trazabilidad.
            logger.log(Level.SEVERE, "Error enviando el email de verificación a " + to + ". Link de verificacion: " + link, ex);
        }
    }

    public void sendInvitationEmail(String to, String companyName, String token) {
        String link = buildInvitationLink(token);
        String subject = "Invitación para unirte a " + companyName;
        String text = "Hola,\n\n" +
                "Te han invitado a unirte a la empresa " + companyName + " en KronoCore.\n" +
                "Acepta la invitación desde este enlace:\n" +
                link + "\n\n" +
                "Si no esperabas este correo, puedes ignorarlo.";

        try {
            JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
            if (mailSender == null) {
                logger.warning("SMTP no configurado. Link de invitacion: " + link);
                return;
            }
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject(subject);
            message.setText(text);
            mailSender.send(message);
        } catch (Exception ex) {
            logger.log(Level.SEVERE, "Error enviando la invitacion a " + to + ". Link: " + link, ex);
        }
    }
}
