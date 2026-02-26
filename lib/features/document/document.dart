// Document Feature Module
// 项目文档管理模块

// Domain
export 'domain/entities/folder.dart';
export 'domain/entities/document.dart';
export 'domain/entities/document_comment.dart';
export 'domain/repositories/document_repository.dart';

// Data
export 'data/models/folder_model.dart';
export 'data/models/document_model.dart';
export 'data/models/document_comment_model.dart';
export 'data/repositories/mock_document_repository.dart';
export 'data/repositories/document_repository_impl.dart';

// Presentation - Bloc
export 'presentation/bloc/document_bloc.dart';
export 'presentation/bloc/folder_bloc.dart';
export 'presentation/bloc/comment_bloc.dart';

// Presentation - Widgets
export 'presentation/widgets/folder_tree.dart';
export 'presentation/widgets/document_card.dart';
export 'presentation/widgets/preview_panel.dart';
export 'presentation/widgets/comment_section.dart';
export 'presentation/widgets/markdown_preview.dart';

// Presentation - Pages
export 'presentation/pages/project_documents_page.dart';
