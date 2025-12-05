import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassroomPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2432),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2432),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(Icons.menu, color: Colors.white),
        ),
        actions: [
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 16),
          CircleAvatar(backgroundColor: Colors.grey.shade400, radius: 18),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourseCard(),
              SizedBox(height: 28),
              _buildFeatureIcons(),
              SizedBox(height: 28),
              _buildAnnouncementBox(),
              SizedBox(height: 24),
              _buildPostCard(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCourseCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC8B6FF), Color(0xFFD4C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFC8B6FF).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Graphic Fundamentals -",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "ART101",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _featureIcon(Icons.edit, "Assignments"),
        _featureIcon(Icons.feedback, "Feedback"),
        _featureIcon(Icons.calendar_today, "TimeTable"),
        _featureIcon(Icons.bar_chart, "Submissions"),
      ],
    );
  }

  Widget _featureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Color(0xFF5B7FFF), size: 28),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnnouncementBox() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Color(0xFF2A3142),
        border: Border.all(color: Colors.white24, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Announce something to your class",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.wifi_tethering, color: Colors.white70, size: 24),
        ],
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A3142),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey.shade400, radius: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Akshay",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Yesterday",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: Colors.white70),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Explore your interests and meet like-minded students by joining one of our many clubs. Whether you're into sports, arts, or academics, there's a club for you. Find your community!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          _buildLinkBox(),
        ],
      ),
    );
  }

  Widget _buildLinkBox() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E2432),
        border: Border.all(color: Colors.white24, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Color(0xFF5B7FFF), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Assignment for Graphic A1 Lesson",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2A3142),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.home, color: Colors.white, size: 28),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF5B7FFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5B7FFF).withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.trending_up, color: Colors.white, size: 26),
            ),
            Icon(Icons.video_call, color: Colors.white, size: 28),
            Icon(Icons.person, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}
