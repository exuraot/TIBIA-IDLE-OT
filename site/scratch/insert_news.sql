-- Ensure table supports utf8mb4
ALTER TABLE `myaac_news` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Clean existing welcome news
DELETE FROM `myaac_news` WHERE `title` LIKE '%Exura%' OR `title` LIKE '%Abertura%';

-- Insert official welcome news
INSERT INTO `myaac_news` (`title`, `body`, `type`, `date`, `category`, `player_id`, `hidden`) VALUES 
(
    'Abertura Oficial: Sejam Bem-vindos ao Mundo de Exura!',
    '<p><img src=\"images/news/announcement.jpg\" style=\"float: right; margin: 0 0 15px 20px; border: 1px solid #793d03; border-radius: 4px; box-shadow: 2px 3px 8px rgba(0,0,0,0.35);\" alt=\"Announcement\" />\nSaudações, nobres aventureiros e desbravadores!</p>\n\n<p>É com imenso orgulho e entusiasmo que anunciamos o <b>lançamento oficial do site e do servidor Exura</b>! Uma nova era se inicia nestas terras místicas, e as portas estão finalmente abertas para acolher guerreiros, paladinos, magos e druidas de todos os reinos.</p>\n\n<p style=\"font-size: 13px; color: #5a2800;\"><b>&diams; Um Mundo Vivo, Focado na Verdadeira Lore</b></p>\n<p>Diferente de servidores comuns focados apenas em números e repetição mecânica, o <b>Exura</b> foi concebido para resgatar a essência e a magia do verdadeiro RPG medieval. Aqui, a <b>Lore</b> e o enredo são os pilares da sua jornada:</p>\n<ul>\n    <li><b>Mistérios e Segredos Ancestrais:</b> Cada masmorra esquecida, biblioteca em ruínas e monumento antigo guarda fragmentos das crônicas que moldaram este continente.</li>\n    <li><b>Quests Narrativas e Desafios Épicos:</b> Missões envolventes onde a atenção aos diálogos dos NPCs, aos livros antigos e à exploração será tão vital quanto a força de sua lâmina.</li>\n    <li><b>Espírito de RPG e Comunidade:</b> Um ambiente preparado para quem valoriza a atmosfera de taverna, o companheirismo das guildas e a emoção de desbravar o desconhecido.</li>\n</ul>\n\n<p style=\"font-size: 13px; color: #5a2800;\"><b>&diams; O Portal Oficial Está Ativo!</b></p>\n<p>Através do nosso site, você já pode dar os primeiros passos rumo à sua lenda:</p>\n<ul>\n    <li><b>Criação de Contas:</b> Acesse a aba <a href=\"?account/create\"><b>Create Account</b></a> para registrar sua conta com segurança.</li>\n    <li><b>Download do Cliente Oficial:</b> O cliente moderno do Exura (versão 15) já está disponível na aba <a href=\"?downloadclient\"><b>Downloads</b></a> — basta baixar, descompactar e entrar direto, sem necessidade de IP Changer ou configurações manuais.</li>\n    <li><b>Rankings e Comunidade:</b> Acompanhe as estatísticas, os guerreiros mais destemidos e as alianças que se erguerão.</li>\n</ul>\n\n<p>Prepare suas mochilas, afie seu aço e estude seus feitiços. A história de Exura começa agora, e é você quem escreverá o próximo capítulo.</p>\n\n<p style=\"margin-top: 25px; padding-top: 10px; border-top: 1px dashed #b59f7b;\">\n<b>Sejam todos muito bem-vindos ao Exura!</b><br/>\n<i>&mdash; A Equipe Exura</i>\n</p>',
    1,
    UNIX_TIMESTAMP(),
    1,
    7,
    0
);
